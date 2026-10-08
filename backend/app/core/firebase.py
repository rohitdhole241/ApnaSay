import os
import json
import base64
import firebase_admin

from firebase_admin import credentials
from firebase_admin import firestore


SERVICE_ACCOUNT_FILE = "serviceAccountKey.json"
FIREBASE_SERVICE_ACCOUNT_BASE64 = os.getenv(
    "FIREBASE_SERVICE_ACCOUNT_BASE64"
)


if not firebase_admin._apps:

    # Render / production
    if FIREBASE_SERVICE_ACCOUNT_BASE64:
        try:
            encoded_credentials = FIREBASE_SERVICE_ACCOUNT_BASE64.strip()

            # Restore missing Base64 padding if necessary
            encoded_credentials += "=" * (-len(encoded_credentials) % 4)

            decoded_json = base64.b64decode(
                encoded_credentials
            ).decode("utf-8")

            service_account_info = json.loads(decoded_json)

            cred = credentials.Certificate(service_account_info)

        except Exception as error:
            raise ValueError(
                "FIREBASE_SERVICE_ACCOUNT_BASE64 contains invalid "
                "Firebase credentials."
            ) from error

    # Local development
    elif os.path.exists(SERVICE_ACCOUNT_FILE):
        cred = credentials.Certificate(SERVICE_ACCOUNT_FILE)

    else:
        raise FileNotFoundError(
            "Firebase credentials not found. "
            "Set FIREBASE_SERVICE_ACCOUNT_BASE64 or "
            "place serviceAccountKey.json inside the backend folder."
        )

    firebase_admin.initialize_app(cred)


db = firestore.client()