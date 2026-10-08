from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path
from typing import Dict, List, Tuple

import joblib
import numpy as np
import pandas as pd

BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))
from sklearn.ensemble import RandomForestRegressor
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics import mean_absolute_error, r2_score
from sklearn.model_selection import train_test_split

from app.ml.features import (
    BASE_WEIGHTS,
    FEATURE_NAMES,
    ML_FEATURE_NAMES,
    _profile_text,
    pair_features,
    priority_weighted_similarity,
)

SEED = 23101
random.seed(SEED)
np.random.seed(SEED)


def as_profile(row: pd.Series) -> Dict[str, object]:
    result = row.to_dict()
    result["age"] = int(result["age"])
    result["hobbies"] = [x.strip() for x in str(result.get("hobbies", "")).split(",") if x.strip()]
    result["compatibility_factors"] = [
        x.strip() for x in str(result.get("compatibility_factors", "")).split(",") if x.strip()
    ]
    return result


def synthetic_target(features: Dict[str, float], query: Dict[str, object], candidate: Dict[str, object]) -> float:
    # Generate realistic labels for the synthetic training set. The trained model then
    # learns non-linear interactions between the profile features.
    core_weights = {
        name: BASE_WEIGHTS[name]
        for name in ML_FEATURE_NAMES
        if name in BASE_WEIGHTS
    }
    base_total = sum(core_weights.values())
    base = sum(features[name] * core_weights[name] for name in core_weights) / base_total
    factor_overlap = features["compatibility_factor_similarity"]
    score = 0.92 * base + 0.08 * factor_overlap
    # Small noise keeps this from being a trivial memorization of an exact formula.
    score += float(np.random.normal(0, 0.012))
    return float(np.clip(score, 0.0, 1.0))


def build_pairs(df: pd.DataFrame, pair_count: int, vectorizer: TfidfVectorizer) -> Tuple[np.ndarray, np.ndarray]:
    profiles = [as_profile(row) for _, row in df.iterrows()]
    text_matrix = vectorizer.transform([_profile_text(profile) for profile in profiles])
    rows: List[List[float]] = []
    targets: List[float] = []
    n = len(profiles)

    # Random pairs teach the general compatibility landscape.
    random_pairs = max(0, pair_count - min(4000, pair_count // 10))
    for _ in range(random_pairs):
        q_idx = random.randrange(n)
        c_idx = random.randrange(n - 1)
        if c_idx >= q_idx:
            c_idx += 1
        query = profiles[q_idx]
        candidate = profiles[c_idx]
        sims = (text_matrix[q_idx] @ text_matrix[c_idx].T).toarray()[0, 0]
        feats = pair_features(query, candidate, text_similarity=float(sims))
        rows.append([feats[name] for name in ML_FEATURE_NAMES])
        targets.append(synthetic_target(feats, query, candidate))

    # Add explicit high-compatibility anchors so the regressor learns that an
    # almost identical lifestyle profile should be near 100%.
    anchor_pairs = pair_count - random_pairs
    for _ in range(anchor_pairs):
        idx = random.randrange(n)
        query = dict(profiles[idx])
        candidate = dict(profiles[idx])
        # Keep the candidate as a separate synthetic entity while preserving the
        # feature vector. Gender is deliberately irrelevant to the model.
        candidate["user_id"] = f"anchor_{idx}"
        feats = pair_features(query, candidate, text_similarity=1.0)
        rows.append([feats[name] for name in ML_FEATURE_NAMES])
        targets.append(1.0)

    return np.asarray(rows, dtype=np.float32), np.asarray(targets, dtype=np.float32)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--profiles", type=int, default=5000)
    parser.add_argument("--pairs", type=int, default=40000)
    parser.add_argument(
        "--data",
        default=str(Path(__file__).resolve().parent / "data" / "roommate_profiles_dummy.csv"),
    )
    parser.add_argument(
        "--model",
        default=str(Path(__file__).resolve().parent / "artifacts" / "roommate_compatibility_model.joblib"),
    )
    args = parser.parse_args()

    data_path = Path(args.data)
    if not data_path.exists():
        raise SystemExit(f"Dataset not found: {data_path}. Run generate_dataset.py first.")
    df = pd.read_csv(data_path).head(args.profiles)

    vectorizer = TfidfVectorizer(
        lowercase=True,
        ngram_range=(1, 2),
        min_df=2,
        max_features=4000,
    )
    vectorizer.fit([_profile_text(as_profile(row)) for _, row in df.iterrows()])
    X, y = build_pairs(df, args.pairs, vectorizer)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=SEED
    )

    model = RandomForestRegressor(
        n_estimators=140,
        max_depth=12,
        min_samples_leaf=2,
        random_state=SEED,
        n_jobs=-1,
    )
    model.fit(X_train, y_train)
    prediction = model.predict(X_test)

    mae = float(mean_absolute_error(y_test, prediction))
    r2 = float(r2_score(y_test, prediction))
    metrics = {
        "model": "RandomForestRegressor",
        "profiles": int(len(df)),
        "training_pairs": int(len(X_train)),
        "test_pairs": int(len(X_test)),
        "mae": mae,
        "r2": r2,
        "mae_percentage_points": mae * 100.0,
        "feature_names": ML_FEATURE_NAMES,
        "random_seed": SEED,
    }

    model_path = Path(args.model)
    model_path.parent.mkdir(parents=True, exist_ok=True)
    bundle = {
        "model": model,
        "vectorizer": vectorizer,
        "feature_names": ML_FEATURE_NAMES,
        "version": "1.0-synthetic-rf",
    }
    joblib.dump(bundle, model_path, compress=3)

    metrics_path = model_path.with_name("training_metrics.json")
    metrics_path.write_text(json.dumps(metrics, indent=2), encoding="utf-8")
    importance_path = model_path.with_name("feature_importance.json")
    importance = {
        name: float(score)
        for name, score in sorted(
            zip(ML_FEATURE_NAMES, model.feature_importances_), key=lambda item: item[1], reverse=True
        )
    }
    importance_path.write_text(json.dumps(importance, indent=2), encoding="utf-8")

    print(f"Model saved to: {model_path}")
    print(json.dumps(metrics, indent=2))
    print("Top features:")
    for name, score in list(importance.items())[:10]:
        print(f"  {name:35s} {score:.4f}")


if __name__ == "__main__":
    main()
