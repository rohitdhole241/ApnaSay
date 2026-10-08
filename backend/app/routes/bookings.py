from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException

from app.core.auth import verify_firebase_token
from app.core.firebase import db
from app.schemas.booking import BookingCreate, BookingUpdate

router = APIRouter(prefix="/bookings", tags=["Bookings"])


APPLICANT_PROFILE_FIELDS = (
    "name", "email", "phone", "photo_url", "bio", "age", "gender",
    "city", "locality", "localities", "budget", "move_in_date",
    "room_type", "pg_type", "distance", "food_preference", "food_habit",
    "cleanliness", "cleanliness_level", "cleaning_frequency",
    "sleep_schedule", "wake_up_time", "noise_preference", "social_level",
    "weekend_lifestyle", "hobbies", "occupation", "college_company",
    "course_job", "study_environment", "preferred_personality",
    "compatibility_factors",
)


def _applicant_profile(user_id: str, booking_data: dict) -> dict:
    """Return only profile fields useful to the PG owner reviewing a request."""
    user_snapshot = db.collection("users").document(user_id).get()
    profile = user_snapshot.to_dict() or {}

    roommate_snapshot = db.collection("roommate_profiles").document(user_id).get()
    roommate_profile = roommate_snapshot.to_dict() or {}
    profile.update(
        {
            key: value
            for key, value in roommate_profile.items()
            if value is not None and value != "" and value != [] and value != {}
        }
    )

    # Older booking documents retain a contact/photo snapshot as a fallback.
    profile.setdefault("name", booking_data.get("user_name"))
    profile.setdefault("email", booking_data.get("user_email"))
    profile.setdefault("photo_url", booking_data.get("user_photo_url"))
    return {
        key: profile[key]
        for key in APPLICANT_PROFILE_FIELDS
        if key in profile and profile[key] is not None
    }


@router.post("/")
def create_booking(
    booking: BookingCreate,
    token: dict = Depends(verify_firebase_token),
):
    uid = token["uid"]
    pg_ref = db.collection("pg_listings").document(booking.pg_id)
    pg_snapshot = pg_ref.get()
    if not pg_snapshot.exists:
        raise HTTPException(status_code=404, detail="PG not found.")

    pg_data = pg_snapshot.to_dict() or {}
    owner_id = pg_data.get("owner_id")
    if not owner_id:
        raise HTTPException(status_code=409, detail="This PG has no assigned owner.")
    if owner_id == uid:
        raise HTTPException(status_code=400, detail="You cannot book your own PG.")
    if pg_data.get("is_available") is not True:
        raise HTTPException(status_code=400, detail="PG is currently unavailable.")

    pending = (
        db.collection("bookings")
        .where("pg_id", "==", booking.pg_id)
        .stream()
    )
    for existing_booking in pending:
        existing_data = existing_booking.to_dict() or {}
        if existing_data.get("user_id") == uid and existing_data.get("status") == "pending":
            raise HTTPException(
                status_code=409,
                detail="You already have a pending request for this PG.",
            )

    user_snapshot = db.collection("users").document(uid).get()
    user_data = user_snapshot.to_dict() or {}
    owner_snapshot = db.collection("users").document(owner_id).get()
    owner_data = owner_snapshot.to_dict() or {}

    data = booking.model_dump(exclude_none=True)
    data.update(
        {
            "user_id": uid,
            "user_name": user_data.get("name", "ApnaStay user"),
            "user_email": user_data.get("email", ""),
            "user_photo_url": user_data.get("photo_url", ""),
            "pg_owner_id": owner_id,
            "owner_name": owner_data.get("name", pg_data.get("owner_name", "PG Owner")),
            "pg_name": pg_data.get("name", "PG listing"),
            "status": "pending",
            "created_at": datetime.now(timezone.utc),
        }
    )
    document = db.collection("bookings").document()
    document.set(data)
    return {"message": "Booking request sent to the PG owner.", "booking_id": document.id, "status": "pending"}


@router.get("/my")
def get_my_bookings(token: dict = Depends(verify_firebase_token)):
    uid = token["uid"]
    collection = db.collection("bookings")
    documents = {}
    for query in (collection.where("user_id", "==", uid), collection.where("applicant_ids", "array_contains", uid)):
        for document in query.stream():
            documents[document.id] = {"id": document.id, **(document.to_dict() or {})}
    return list(documents.values())


@router.get("/owner")
def get_owner_bookings(token: dict = Depends(verify_firebase_token)):
    uid = token["uid"]
    profile = db.collection("users").document(uid).get()
    if not profile.exists or (profile.to_dict() or {}).get("role") != "pg_owner":
        raise HTTPException(status_code=403, detail="Only PG owners can view booking requests.")
    documents = db.collection("bookings").where("pg_owner_id", "==", uid).stream()
    bookings = []
    for document in documents:
        data = document.to_dict() or {}
        user_id = data.get("user_id")
        data["requester"] = _applicant_profile(user_id, data) if user_id else {}
        data["co_applicants"] = [_applicant_profile(applicant_id, {}) for applicant_id in data.get("applicant_ids", []) if applicant_id != user_id]
        bookings.append({"id": document.id, **data})
    return bookings


@router.patch("/{booking_id}")
def update_booking(
    booking_id: str,
    booking: BookingUpdate,
    token: dict = Depends(verify_firebase_token),
):
    document_ref = db.collection("bookings").document(booking_id)
    snapshot = document_ref.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Booking request not found.")

    existing = snapshot.to_dict() or {}
    uid = token["uid"]
    status = booking.status
    if existing.get("status") != "pending":
        raise HTTPException(status_code=409, detail="This booking request has already been answered.")
    if existing.get("pg_owner_id") == uid:
        if status not in {"accepted", "declined"}:
            raise HTTPException(status_code=400, detail="Owners can accept or decline a request.")
    elif existing.get("user_id") == uid:
        if status != "cancelled":
            raise HTTPException(status_code=400, detail="You can only cancel your own pending request.")
    else:
        raise HTTPException(status_code=403, detail="You are not allowed to update this booking request.")

    now = datetime.now(timezone.utc)
    document_ref.update({"status": status, "updated_at": now})
    proposal_id = existing.get("roommate_proposal_id")
    if proposal_id and existing.get("pg_owner_id") == uid:
        proposal_status = "pg_accepted" if status == "accepted" else "pg_declined"
        db.collection("roommate_pg_proposals").document(proposal_id).update({"status": proposal_status, "updated_at": now})
    return {"message": "Booking request updated.", "booking_id": booking_id, "status": status}
