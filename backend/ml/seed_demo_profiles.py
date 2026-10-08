from __future__ import annotations

import argparse
import csv
from pathlib import Path

from firebase_admin import credentials, firestore, initialize_app, _apps


def get_db(service_account: Path):
    if not _apps:
        initialize_app(credentials.Certificate(str(service_account)))
    return firestore.client()


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed synthetic ApnaStay roommate profiles into Firestore.")
    parser.add_argument(
        "--service-account",
        default="serviceAccountKey.json",
        help="Path to Firebase Admin SDK service-account JSON (keep this file out of Git).",
    )
    parser.add_argument(
        "--csv",
        default=str(Path(__file__).resolve().parent / "data" / "roommate_profiles_dummy.csv"),
    )
    parser.add_argument("--count", type=int, default=25)
    parser.add_argument("--prefix", default="demo_")
    args = parser.parse_args()

    service_account = Path(args.service_account)
    if not service_account.exists():
        raise SystemExit(
            f"Firebase service account not found: {service_account}\n"
            "Provide it with --service-account. Do not commit the credential file."
        )

    db = get_db(service_account)
    with Path(args.csv).open(newline="", encoding="utf-8") as handle:
        rows = list(csv.DictReader(handle))[: max(0, args.count)]

    for row in rows:
        uid = f"{args.prefix}{row['user_id']}"
        payload = dict(row)
        payload["uid"] = uid
        payload["age"] = int(row["age"]) if row.get("age") else None
        payload["hobbies"] = [x.strip() for x in row.get("hobbies", "").split(",") if x.strip()]
        payload["compatibility_factors"] = [
            x.strip() for x in row.get("compatibility_factors", "").split(",") if x.strip()
        ]
        payload.pop("user_id", None)
        db.collection("roommate_profiles").document(uid).set(payload, merge=True)

    print(f"Seeded {len(rows)} demo roommate profiles into Firestore collection 'roommate_profiles'.")
    print("These are demo documents only; no Firebase Authentication accounts are created for them.")


if __name__ == "__main__":
    main()
