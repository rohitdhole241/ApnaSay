from datetime import datetime, timezone
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException

from app.core.auth import verify_firebase_token
from app.core.firebase import db
from app.schemas.meal_booking import MealBookingCreate, MealBookingUpdate

router = APIRouter(prefix="/meal-bookings", tags=["Meal Bookings"])

APPLICANT_FIELDS = (
    "name", "email", "phone", "photo_url", "age", "gender", "bio",
    "city", "locality", "occupation", "college_company", "course_job",
    "food_preference", "food_habit", "hobbies",
)


def _requester_profile(user_id: str, booking: dict) -> dict:
    snapshot = db.collection("users").document(user_id).get()
    profile = snapshot.to_dict() or {}
    return {
        key: profile[key]
        for key in APPLICANT_FIELDS
        if key in profile and profile[key] is not None
    }


@router.post("/")
def create_meal_booking(
    booking: MealBookingCreate,
    token: dict = Depends(verify_firebase_token),
):
    user_id = token["uid"]
    provider_ref = db.collection("users").document(booking.provider_uid)
    provider_snapshot = provider_ref.get()
    if not provider_snapshot.exists:
        raise HTTPException(status_code=404, detail="Meal provider not found.")
    provider = provider_snapshot.to_dict() or {}
    if provider.get("role") != "meal_provider":
        raise HTTPException(status_code=409, detail="This account is not a meal provider.")
    if user_id == booking.provider_uid:
        raise HTTPException(status_code=400, detail="You cannot book your own meal service.")

    user_snapshot = db.collection("users").document(user_id).get()
    if not user_snapshot.exists:
        raise HTTPException(status_code=404, detail="Your user profile was not found.")
    user = user_snapshot.to_dict() or {}

    existing_requests = db.collection("meal_bookings").where(
        "user_id", "==", user_id
    ).stream()
    for existing in existing_requests:
        existing_data = existing.to_dict() or {}
        if (
            existing_data.get("provider_uid") == booking.provider_uid
            and existing_data.get("status") == "pending"
        ):
            raise HTTPException(
                status_code=409,
                detail="You already have a pending request with this meal provider.",
            )

    data = booking.model_dump()
    data.update(
        {
            "user_id": user_id,
            "user_name": user.get("name", "ApnaStay user"),
            "user_email": user.get("email", ""),
            "user_photo_url": user.get("photo_url", ""),
            "provider_uid": booking.provider_uid,
            "provider_name": provider.get("provider_name") or provider.get("name", "Meal provider"),
            "status": "pending",
            "created_at": datetime.now(timezone.utc),
            "updated_at": datetime.now(timezone.utc),
        }
    )
    document = db.collection("meal_bookings").document()
    document.set(data)
    return {
        "message": "Meal service request sent to the provider.",
        "booking_id": document.id,
        "status": "pending",
    }


@router.get("/my")
def get_my_meal_bookings(token: dict = Depends(verify_firebase_token)):
    user_id = token["uid"]
    documents = db.collection("meal_bookings").where("user_id", "==", user_id).stream()
    return [{"id": document.id, **(document.to_dict() or {})} for document in documents]


@router.get("/provider")
def get_provider_meal_bookings(token: dict = Depends(verify_firebase_token)):
    provider_uid = token["uid"]
    provider = db.collection("users").document(provider_uid).get()
    if not provider.exists or (provider.to_dict() or {}).get("role") != "meal_provider":
        raise HTTPException(status_code=403, detail="Only meal providers can view service requests.")

    documents = (
        db.collection("meal_bookings")
        .where("provider_uid", "==", provider_uid)
        .stream()
    )
    bookings = []
    for document in documents:
        data = document.to_dict() or {}
        user_id = data.get("user_id")
        requester = _requester_profile(user_id, data) if user_id else {}
        if not requester.get("name"):
            requester["name"] = data.get("user_name", "ApnaStay user")
        if not requester.get("email"):
            requester["email"] = data.get("user_email", "")
        if not requester.get("photo_url"):
            requester["photo_url"] = data.get("user_photo_url", "")
        data["requester"] = requester
        bookings.append({"id": document.id, **data})
    return bookings


@router.patch("/{booking_id}")
def update_meal_booking(
    booking_id: str,
    booking: MealBookingUpdate,
    token: dict = Depends(verify_firebase_token),
):
    if booking.status not in {"accepted", "declined"}:
        raise HTTPException(status_code=400, detail="Choose accepted or declined.")

    provider_uid = token["uid"]
    provider = db.collection("users").document(provider_uid).get()
    if not provider.exists or (provider.to_dict() or {}).get("role") != "meal_provider":
        raise HTTPException(status_code=403, detail="Only meal providers can respond to requests.")

    document_ref = db.collection("meal_bookings").document(booking_id)
    snapshot = document_ref.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Meal service request not found.")

    existing = snapshot.to_dict() or {}
    if existing.get("provider_uid") != provider_uid:
        raise HTTPException(status_code=403, detail="You cannot respond to this request.")
    if existing.get("status") != "pending":
        raise HTTPException(status_code=409, detail="This request has already been answered.")

    now = datetime.now(timezone.utc)
    document_ref.update({"status": booking.status, "updated_at": now})
    return {
        "message": "Meal service request updated.",
        "booking_id": booking_id,
        "status": booking.status,
    }
