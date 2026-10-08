from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Dict, List, Mapping, Sequence

import joblib
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from .features import FEATURE_NAMES, explain_match, feature_vector, pair_features, _profile_text


ARTIFACT_DIR = Path(__file__).resolve().parents[2] / "ml" / "artifacts"
MODEL_PATH = ARTIFACT_DIR / "roommate_compatibility_model.joblib"


class RoommateRecommender:
    def __init__(self, model_path: Path = MODEL_PATH) -> None:
        if not model_path.exists():
            raise FileNotFoundError(
                f"ML model not found at {model_path}. Run backend/ml/train_model.py first."
            )
        bundle = joblib.load(model_path)
        self.model = bundle["model"]
        self.vectorizer: TfidfVectorizer = bundle["vectorizer"]
        self.feature_names: Sequence[str] = bundle.get("feature_names", FEATURE_NAMES)
        self.version = bundle.get("version", "1.0")

    @staticmethod
    def _clip_score(value: float) -> int:
        return int(round(max(0.0, min(100.0, value))))

    def recommend(
        self,
        query: Mapping[str, Any],
        candidates: Sequence[Mapping[str, Any]],
        *,
        top_k: int = 20,
    ) -> List[Dict[str, Any]]:
        if not candidates:
            return []

        # Transform all text once, then calculate each query/candidate text similarity.
        texts = [_profile_text(query)] + [_profile_text(candidate) for candidate in candidates]
        vectors = self.vectorizer.transform(texts)
        query_text_vector = vectors[0]
        candidate_text_vectors = vectors[1:]
        text_scores = cosine_similarity(query_text_vector, candidate_text_vectors).ravel()

        feature_rows: List[List[float]] = []
        raw_feature_rows: List[Dict[str, float]] = []
        for idx, candidate in enumerate(candidates):
            text_score = float(text_scores[idx]) if idx < len(text_scores) else 0.5
            raw = pair_features(query, candidate, text_similarity=text_score)
            raw_feature_rows.append(raw)
            feature_rows.append([raw[name] for name in self.feature_names])

        predictions = self.model.predict(np.asarray(feature_rows, dtype=np.float32))
        ranked: List[Dict[str, Any]] = []
        for candidate, prediction, raw in zip(candidates, predictions, raw_feature_rows):
            ml_score = float(prediction) if float(prediction) <= 1.5 else float(prediction) / 100.0
            # Personalize the model output using the compatibility factors the
            # current user selected on the existing Profile page. No new field
            # is required and gender is not part of this calculation.
            final_score = (
                0.77 * ml_score
                + 0.15 * raw["priority_weighted_similarity"]
                + 0.08 * raw["text_similarity"]
            )
            score = self._clip_score(final_score * 100.0)
            reasons = explain_match(query, candidate, raw)
            ranked.append(
                {
                    **dict(candidate),
                    "compatibility_score": score,
                    "match_reasons": reasons,
                    "ml_model_version": self.version,
                }
            )

        ranked.sort(key=lambda item: item["compatibility_score"], reverse=True)
        return ranked[: max(1, min(top_k, len(ranked)))]


_RECOMMENDER: RoommateRecommender | None = None


def get_recommender() -> RoommateRecommender:
    global _RECOMMENDER
    if _RECOMMENDER is None:
        _RECOMMENDER = RoommateRecommender()
    return _RECOMMENDER


__all__ = ["RoommateRecommender", "get_recommender", "MODEL_PATH"]
