from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException

from app.core.firebase import db
from app.core.auth import verify_firebase_token

from app.schemas.user import (
    UserCreate,
    UserUpdate,
)


router = APIRouter(
    prefix="/users",
    tags=["Users"],
)


# --------------------------------------------------
# Create / update user profile
# --------------------------------------------------

@router.post("/")
def create_user(
    user: UserCreate,
    token: dict = Depends(verify_firebase_token),
):

    uid = token["uid"]

    data = user.model_dump(exclude={"password"}, exclude_none=True)

    data["uid"] = uid

    user_ref = db.collection("users").document(uid)
    existing_user = user_ref.get()
    existing_data = existing_user.to_dict() or {}

    if existing_user.exists:
        # A profile refresh may update user details, but cannot change its role
        # or original creation time through this endpoint.
        data.pop("role", None)
        data.pop("created_at", None)
        user_ref.set(data, merge=True)
    else:
        data["created_at"] = datetime.now(timezone.utc)
        user_ref.set(data)

    return {
        "message": "User profile saved successfully",
        "uid": uid,
        "role": existing_data.get("role", "user")
        if existing_user.exists
        else user.role,
        "gender": user.gender or existing_data.get("gender")
        if existing_user.exists
        else user.gender,
    }


# --------------------------------------------------
# Get current user
# --------------------------------------------------

@router.get("/me")
def get_current_user(
    token: dict = Depends(verify_firebase_token),
):

    uid = token["uid"]

    document = (
        db.collection("users")
        .document(uid)
        .get()
    )

    if not document.exists:

        raise HTTPException(
            status_code=404,
            detail="User profile not found",
        )

    return {
        "uid": uid,
        **document.to_dict(),
    }


# --------------------------------------------------
# Update current user
# --------------------------------------------------

@router.put("/me")
def update_current_user(
    user: UserUpdate,
    token: dict = Depends(verify_firebase_token),
):

    uid = token["uid"]

    data = {
        key: value
        for key, value in user.model_dump(exclude={"password"}).items()
        if value is not None
    }

    if not data:

        raise HTTPException(
            status_code=400,
            detail="No fields provided for update",
        )

    db.collection("users").document(uid).set(data, merge=True)

    return {
        "message": "User profile updated successfully",
    }


# --------------------------------------------------
# Delete user profile
# --------------------------------------------------

@router.delete("/me")
def delete_current_user(
    token: dict = Depends(verify_firebase_token),
):

    uid = token["uid"]

    db.collection("users").document(uid).delete()

    return {
        "message": "User profile deleted successfully",
    }
