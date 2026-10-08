import os
import firebase_admin

from firebase_admin import credentials
from firebase_admin import firestore


SERVICE_ACCOUNT_FILE = "serviceAccountKey.json"


if not firebase_admin._apps:

    if not os.path.exists(SERVICE_ACCOUNT_FILE):
        raise FileNotFoundError(
            "serviceAccountKey.json not found. "
            "Place the Firebase Admin SDK service account "
            "file inside the backend folder."
        )

    cred = credentials.Certificate(SERVICE_ACCOUNT_FILE)

    firebase_admin.initialize_app(cred)


db = firestore.client()