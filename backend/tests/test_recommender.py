import copy

import pandas as pd

from app.ml.features import pair_features
from app.ml.recommender import get_recommender
from ml.train_model import as_profile


def _profiles():
    df = pd.read_csv('ml/data/roommate_profiles_dummy.csv')
    query = as_profile(df.iloc[0])
    return query


def test_identical_lifestyle_can_score_near_100_even_with_different_gender():
    query = _profiles()
    candidate = copy.deepcopy(query)
    candidate["user_id"] = "candidate"
    candidate["gender"] = "Female" if query.get("gender") != "Female" else "Male"
    result = get_recommender().recommend(query, [candidate], top_k=1)[0]
    assert result["compatibility_score"] >= 95


def test_gender_is_not_a_matching_feature():
    query = _profiles()
    male = copy.deepcopy(query)
    male["gender"] = "Male"
    female = copy.deepcopy(query)
    female["gender"] = "Female"
    male["user_id"] = "male"
    female["user_id"] = "female"
    recommender = get_recommender()
    male_score = recommender.recommend(query, [male], top_k=1)[0]["compatibility_score"]
    female_score = recommender.recommend(query, [female], top_k=1)[0]["compatibility_score"]
    assert abs(male_score - female_score) <= 1


def test_preference_factors_change_the_pair_features():
    query = _profiles()
    candidate = copy.deepcopy(query)
    base = pair_features(query, candidate, text_similarity=1.0)
    query["compatibility_factors"] = ["Sleep schedule"]
    prioritized = pair_features(query, candidate, text_similarity=1.0)
    assert prioritized["priority_weighted_similarity"] >= base["priority_weighted_similarity"] - 0.001
