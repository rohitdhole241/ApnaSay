from __future__ import annotations

import re
from datetime import date, datetime
from typing import Any, Dict, Iterable, List, Mapping, Sequence, Set


FEATURE_NAMES = [
    "age_similarity",
    "budget_similarity",
    "city_similarity",
    "locality_similarity",
    "move_in_similarity",
    "room_type_similarity",
    "pg_type_similarity",
    "distance_preference_similarity",
    "food_preference_similarity",
    "food_habit_similarity",
    "cleanliness_similarity",
    "cleaning_frequency_similarity",
    "sleep_schedule_similarity",
    "wake_up_time_similarity",
    "noise_preference_similarity",
    "social_level_similarity",
    "weekend_lifestyle_similarity",
    "hobbies_similarity",
    "occupation_similarity",
    "study_environment_similarity",
    "text_similarity",
    "priority_weighted_similarity",
    "compatibility_factor_similarity",
]

# The Random Forest learns the core compatibility attributes.
# The user's selected compatibility factors are applied as a personalized
# ranking layer after the ML prediction rather than dominating training.
ML_FEATURE_NAMES = [
    name
    for name in FEATURE_NAMES
    if name not in {"priority_weighted_similarity", "text_similarity"}
]

# The model intentionally does NOT use the user's own gender as a roommate filter
# or matching signal. Both male and female profiles can be recommended.
BASE_WEIGHTS = {
    "age_similarity": 0.03,
    "budget_similarity": 0.11,
    "city_similarity": 0.08,
    "locality_similarity": 0.08,
    "move_in_similarity": 0.05,
    "room_type_similarity": 0.04,
    "pg_type_similarity": 0.03,
    "distance_preference_similarity": 0.03,
    "food_preference_similarity": 0.08,
    "food_habit_similarity": 0.04,
    "cleanliness_similarity": 0.10,
    "cleaning_frequency_similarity": 0.05,
    "sleep_schedule_similarity": 0.10,
    "wake_up_time_similarity": 0.04,
    "noise_preference_similarity": 0.08,
    "social_level_similarity": 0.07,
    "weekend_lifestyle_similarity": 0.05,
    "hobbies_similarity": 0.07,
    "occupation_similarity": 0.03,
    "study_environment_similarity": 0.05,
    "text_similarity": 0.04,
}

PRIORITY_TO_FEATURE = {
    "cleanliness": "cleanliness_similarity",
    "budget": "budget_similarity",
    "sleep schedule": "sleep_schedule_similarity",
    "food": "food_preference_similarity",
    "privacy": "noise_preference_similarity",
    "location": "locality_similarity",
}


def _norm(value: Any) -> str:
    if value is None:
        return ""
    return re.sub(r"\s+", " ", str(value).strip().lower())


def _list(value: Any) -> List[str]:
    if isinstance(value, (list, tuple, set)):
        return [_norm(v) for v in value if _norm(v)]
    if value is None:
        return []
    text = str(value).strip()
    if not text:
        return []
    return [_norm(v) for v in re.split(r"[,;/|]+", text) if _norm(v)]


def _set(value: Any) -> Set[str]:
    return set(_list(value))


def _is_no_pref(value: Any) -> bool:
    return _norm(value) in {"", "no preference", "any", "any room", "any pg", "flexible"}


def _exact_or_no_pref(a: Any, b: Any) -> float:
    a_norm, b_norm = _norm(a), _norm(b)
    if not a_norm or not b_norm:
        return 0.5
    if a_norm == b_norm:
        return 1.0
    if _is_no_pref(a_norm) or _is_no_pref(b_norm):
        return 1.0
    return 0.0


def _ordinal_similarity(a: Any, b: Any, order: Sequence[str]) -> float:
    a_norm, b_norm = _norm(a), _norm(b)
    if not a_norm or not b_norm:
        return 0.5
    try:
        ai, bi = order.index(a_norm), order.index(b_norm)
    except ValueError:
        return _exact_or_no_pref(a_norm, b_norm)
    if len(order) <= 1:
        return 1.0
    return max(0.0, 1.0 - abs(ai - bi) / (len(order) - 1))


def _budget_value(value: Any) -> float | None:
    if value is None:
        return None
    text = str(value).replace(",", "").strip()
    match = re.search(r"\d+(?:\.\d+)?", text)
    return float(match.group()) if match else None


def _budget_similarity(a: Any, b: Any) -> float:
    av, bv = _budget_value(a), _budget_value(b)
    if av is None or bv is None or max(av, bv) <= 0:
        return 0.5
    return max(0.0, 1.0 - abs(av - bv) / max(av, bv))


def _age_similarity(a: Any, b: Any) -> float:
    try:
        av, bv = float(a), float(b)
    except (TypeError, ValueError):
        return 0.5
    return max(0.0, 1.0 - min(abs(av - bv) / 12.0, 1.0))


def _jaccard(a: Any, b: Any) -> float:
    sa, sb = _set(a), _set(b)
    if not sa and not sb:
        return 0.5
    if not sa or not sb:
        return 0.0
    return len(sa & sb) / len(sa | sb)


def _locality_tokens(value: Any) -> Set[str]:
    text = _norm(value)
    if not text:
        return set()
    # Localities are usually comma separated; keep words together where possible.
    parts = [p.strip() for p in re.split(r"[,;/|]+", text) if p.strip()]
    return set(parts)


def _locality_similarity(a: Any, b: Any) -> float:
    sa, sb = _locality_tokens(a), _locality_tokens(b)
    if not sa or not sb:
        return 0.5
    return len(sa & sb) / len(sa | sb)


def _parse_date(value: Any) -> date | None:
    text = _norm(value)
    if not text:
        return None
    for fmt in ("%Y-%m-%d", "%d-%m-%Y", "%d/%m/%Y", "%Y/%m/%d"):
        try:
            return datetime.strptime(text, fmt).date()
        except ValueError:
            continue
    return None


def _date_similarity(a: Any, b: Any) -> float:
    av, bv = _parse_date(a), _parse_date(b)
    if av is None or bv is None:
        return 0.5
    return max(0.0, 1.0 - min(abs((av - bv).days) / 90.0, 1.0))


def _distance_value(value: Any) -> float | None:
    match = re.search(r"(\d+(?:\.\d+)?)", _norm(value))
    return float(match.group(1)) if match else None


def _distance_similarity(a: Any, b: Any) -> float:
    av, bv = _distance_value(a), _distance_value(b)
    if av is None or bv is None:
        return 0.5
    return max(0.0, 1.0 - min(abs(av - bv) / 8.0, 1.0))


def _profile_text(profile: Mapping[str, Any]) -> str:
    values = [
        profile.get("bio", ""),
        profile.get("college_company", ""),
        profile.get("course_job", ""),
        profile.get("occupation", ""),
        profile.get("study_environment", ""),
        " ".join(_list(profile.get("hobbies"))),
    ]
    return " ".join(str(v).strip() for v in values if str(v).strip())


def raw_similarities(query: Mapping[str, Any], candidate: Mapping[str, Any]) -> Dict[str, float]:
    return {
        "age_similarity": _age_similarity(query.get("age"), candidate.get("age")),
        "budget_similarity": _budget_similarity(query.get("budget"), candidate.get("budget")),
        "city_similarity": _exact_or_no_pref(query.get("city"), candidate.get("city")),
        "locality_similarity": _locality_similarity(
            query.get("localities", query.get("locality")),
            candidate.get("localities", candidate.get("locality")),
        ),
        "move_in_similarity": _date_similarity(query.get("move_in_date"), candidate.get("move_in_date")),
        "room_type_similarity": _exact_or_no_pref(query.get("room_type"), candidate.get("room_type")),
        "pg_type_similarity": _exact_or_no_pref(query.get("pg_type"), candidate.get("pg_type")),
        "distance_preference_similarity": _distance_similarity(query.get("distance"), candidate.get("distance")),
        "food_preference_similarity": _exact_or_no_pref(
            query.get("food_preference"), candidate.get("food_preference")
        ),
        "food_habit_similarity": _exact_or_no_pref(query.get("food_habit"), candidate.get("food_habit")),
        "cleanliness_similarity": _ordinal_similarity(
            query.get("cleanliness_level", query.get("cleanliness")),
            candidate.get("cleanliness_level", candidate.get("cleanliness")),
            ["relaxed", "balanced", "very particular"],
        ),
        "cleaning_frequency_similarity": _ordinal_similarity(
            query.get("cleaning_frequency"),
            candidate.get("cleaning_frequency"),
            ["when needed", "weekly", "daily"],
        ),
        "sleep_schedule_similarity": _ordinal_similarity(
            query.get("sleep_schedule"),
            candidate.get("sleep_schedule"),
            ["early sleeper", "flexible", "night owl"],
        ),
        "wake_up_time_similarity": _ordinal_similarity(
            query.get("wake_up_time"),
            candidate.get("wake_up_time"),
            ["before 7 am", "7-9 am", "after 9 am"],
        ),
        "noise_preference_similarity": _ordinal_similarity(
            query.get("noise_preference"),
            candidate.get("noise_preference"),
            ["quiet", "moderate", "lively"],
        ),
        "social_level_similarity": _ordinal_similarity(
            query.get("social_level"),
            candidate.get("social_level"),
            ["introvert", "balanced", "very social"],
        ),
        "weekend_lifestyle_similarity": _ordinal_similarity(
            query.get("weekend_lifestyle"),
            candidate.get("weekend_lifestyle"),
            ["mostly at home", "mix of both", "out and about"],
        ),
        "hobbies_similarity": _jaccard(query.get("hobbies"), candidate.get("hobbies")),
        "occupation_similarity": _exact_or_no_pref(query.get("occupation"), candidate.get("occupation")),
        "study_environment_similarity": _ordinal_similarity(
            query.get("study_environment"),
            candidate.get("study_environment"),
            ["quiet", "flexible", "collaborative"],
        ),
        # Text similarity is filled by add_text_similarity().
        "text_similarity": 0.5,
    }


def priority_weighted_similarity(
    similarities: Mapping[str, float],
    priorities: Any,
) -> float:
    weights = dict(BASE_WEIGHTS)
    selected = _set(priorities)
    for priority in selected:
        feature = PRIORITY_TO_FEATURE.get(priority)
        if feature:
            weights[feature] *= 2.2
    total = sum(weights.values())
    if total <= 0:
        return 0.5
    return sum(similarities.get(name, 0.5) * weight for name, weight in weights.items()) / total


def pair_features(
    query: Mapping[str, Any],
    candidate: Mapping[str, Any],
    *,
    text_similarity: float = 0.5,
) -> Dict[str, float]:
    sims = raw_similarities(query, candidate)
    sims["text_similarity"] = float(max(0.0, min(1.0, text_similarity)))
    sims["priority_weighted_similarity"] = priority_weighted_similarity(
        sims, query.get("compatibility_factors", [])
    )
    sims["compatibility_factor_similarity"] = _jaccard(
        query.get("compatibility_factors", []),
        candidate.get("compatibility_factors", []),
    )
    return {name: float(sims.get(name, 0.5)) for name in FEATURE_NAMES}


def feature_vector(
    query: Mapping[str, Any],
    candidate: Mapping[str, Any],
    *,
    text_similarity: float = 0.5,
) -> List[float]:
    features = pair_features(query, candidate, text_similarity=text_similarity)
    return [features[name] for name in FEATURE_NAMES]


def explain_match(
    query: Mapping[str, Any],
    candidate: Mapping[str, Any],
    similarities: Mapping[str, float],
) -> List[str]:
    labels = {
        "budget_similarity": "Similar monthly budget",
        "city_similarity": "Same city",
        "locality_similarity": "Preferred localities overlap",
        "move_in_similarity": "Similar move-in timing",
        "food_preference_similarity": "Same food preference",
        "food_habit_similarity": "Similar food habits",
        "cleanliness_similarity": "Similar cleanliness preference",
        "cleaning_frequency_similarity": "Similar cleaning routine",
        "sleep_schedule_similarity": "Similar sleep schedule",
        "wake_up_time_similarity": "Similar wake-up time",
        "noise_preference_similarity": "Similar noise preference",
        "social_level_similarity": "Similar social lifestyle",
        "weekend_lifestyle_similarity": "Similar weekend lifestyle",
        "hobbies_similarity": "Shared interests",
        "occupation_similarity": "Similar occupation",
        "study_environment_similarity": "Similar study/work environment",
        "text_similarity": "Similar profile description",
        "room_type_similarity": "Compatible room preference",
        "pg_type_similarity": "Compatible PG preference",
    }
    priorities = _set(query.get("compatibility_factors", []))
    scored = []
    for feature, label in labels.items():
        score = float(similarities.get(feature, 0.0))
        bonus = 1.20 if PRIORITY_TO_FEATURE.get(next((p for p in priorities if PRIORITY_TO_FEATURE.get(p) == feature), "")) else 1.0
        scored.append((score * bonus, score, label))
    scored.sort(reverse=True, key=lambda item: item[0])
    reasons = [label for _, score, label in scored if score >= 0.65][:4]
    return reasons or ["Lifestyle preferences are reasonably compatible"]


__all__ = [
    "FEATURE_NAMES",
    "ML_FEATURE_NAMES",
    "BASE_WEIGHTS",
    "pair_features",
    "feature_vector",
    "raw_similarities",
    "priority_weighted_similarity",
    "explain_match",
    "_profile_text",
]
