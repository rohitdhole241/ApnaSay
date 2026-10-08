from fastapi import Header, HTTPException
from firebase_admin import auth


def verify_firebase_token(
    authorization: str | None = Header(default=None)
):
    if not authorization:
        raise HTTPException(
            status_code=401,
            detail="Authorization header is missing",
        )

    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="Invalid authorization format",
        )

    token = authorization.replace("Bearer ", "", 1)

    try:
        decoded_token = auth.verify_id_token(token)

        return decoded_token

    except Exception:
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired Firebase token",
        )