# ApnaStay Roommate Matching ML

This module implements the roommate recommendation feature using the **existing Complete Your Profile fields**. No new profile field is required.

## Model

A `RandomForestRegressor` is trained on synthetic **ordered roommate pairs**. Each pair is converted to compatibility features such as budget similarity, locality overlap, sleep-schedule similarity, cleanliness similarity, hobby overlap, and move-in timing.

The user's existing **Compatibility Factors** are used to give extra weight to the attributes they selected.

The user's own gender is intentionally **not** used as a filter or model feature. Recommendations can contain male, female, and non-binary profiles.

## Generate the dummy dataset

```bash
cd backend
python ml/generate_dataset.py --rows 5000
```

## Train the model

```bash
cd backend
python ml/train_model.py --profiles 5000 --pairs 40000
```

Artifacts are written to `backend/ml/artifacts/`.

## Live API

The backend exposes:

```text
GET /roommates/recommendations?top_k=20
```

The endpoint reads the signed-in user's saved profile, compares it with all eligible roommate profiles from Firestore, predicts compatibility, ranks the results, and returns a compatibility percentage plus short match reasons.

## Seed demo roommate profiles (optional)

To make the matching page immediately testable without waiting for real users to create profiles:

```bash
cd backend
python ml/seed_demo_profiles.py --service-account serviceAccountKey.json --count 25
```

This writes demo documents to Firestore's `roommate_profiles` collection. It does **not** create Firebase Authentication accounts for the demo profiles.
