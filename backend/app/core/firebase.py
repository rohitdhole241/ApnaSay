import os
import json
import firebase_admin

from firebase_admin import credentials
from firebase_admin import firestore


SERVICE_ACCOUNT_FILE = "serviceAccountKey.json"
FIREBASE_SERVICE_ACCOUNT_JSON = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")


if not firebase_admin._apps:

    # Render / production
    if FIREBASE_SERVICE_ACCOUNT_JSON:
        try:
            service_account_info = json.loads(FIREBASE_SERVICE_ACCOUNT_JSON)
            cred = credentials.Certificate(service_account_info)
        except json.JSONDecodeError as error:
            raise ValueError(
                "FIREBASE_SERVICE_ACCOUNT_JSON contains invalid JSON."
            ) from error

    # Local development
    elif os.path.exists(SERVICE_ACCOUNT_FILE):
        cred = credentials.Certificate(SERVICE_ACCOUNT_FILE)

    # Nothing available
    else:
        raise FileNotFoundError(
            "Firebase credentials not found. "
            "Set FIREBASE_SERVICE_ACCOUNT_JSON or "
            "place serviceAccountKey.json inside the backend folder."
        )

    firebase_admin.initialize_app(cred)


db = firestore.client()