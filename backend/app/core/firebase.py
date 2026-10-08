import os
import firebase_admin

from firebase_admin import credentials
from firebase_admin import firestore


SERVICE_ACCOUNT_FILE = "serviceAccountKey.json"


def get_firebase_credentials():
    project_id = os.getenv("FIREBASE_PROJECT_ID")
    private_key_id = os.getenv("FIREBASE_PRIVATE_KEY_ID")
    private_key = os.getenv("FIREBASE_PRIVATE_KEY")
    client_email = os.getenv("FIREBASE_CLIENT_EMAIL")
    client_id = os.getenv("FIREBASE_CLIENT_ID")
    client_x509_cert_url = os.getenv(
        "FIREBASE_CLIENT_X509_CERT_URL"
    )

    # Safe diagnostic check.
    # This prints only True/False, never the actual credentials.
    print("Firebase environment check:")
    print("PROJECT_ID:", bool(project_id))
    print("CLIENT_EMAIL:", bool(client_email))
    print("PRIVATE_KEY:", bool(private_key))

    # Render / production
    if project_id and private_key and client_email:

        service_account_info = {
            "type": "service_account",
            "project_id": project_id,
            "private_key_id": private_key_id or "",
            "private_key": private_key.replace("\\n", "\n"),
            "client_email": client_email,
            "client_id": client_id or "",
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url": (
                "https://www.googleapis.com/oauth2/v1/certs"
            ),
            "client_x509_cert_url": client_x509_cert_url or "",
        }

        return credentials.Certificate(service_account_info)

    # Local development
    if os.path.exists(SERVICE_ACCOUNT_FILE):
        print("Using local serviceAccountKey.json")
        return credentials.Certificate(SERVICE_ACCOUNT_FILE)

    raise FileNotFoundError(
        "Firebase credentials not found. "
        "Configure Firebase environment variables on Render "
        "or place serviceAccountKey.json in the backend folder."
    )


if not firebase_admin._apps:
    cred = get_firebase_credentials()
    firebase_admin.initialize_app(cred)


db = firestore.client()