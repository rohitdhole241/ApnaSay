from datetime import datetime, timezone
import hashlib

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Query,
)

from app.core.firebase import db
from app.core.auth import verify_firebase_token

from app.schemas.roommate import (
    RoommateDecisionRequest,
    RoommateProfileCreate,
    RoommateRequestCreate,
    RoommateRequestResponse,
    RoommateProfileUpdate,
)
from app.ml.recommender import get_recommender


router = APIRouter(
    prefix="/roommates",
    tags=["Roommates"],
)


def _collect_roommate_profiles() -> dict[str, dict]:
    """Merge the two Firestore profile locations used by the app."""
    user_profiles = {
        document.id: document.to_dict() or {}
        for document in db.collection("users").stream()
    }
    roommate_profiles = {
        document.id: document.to_dict() or {}
        for document in db.collection("roommate_profiles").stream()
    }

    merged: dict[str, dict] = {}
    uids = list(user_profiles)
    uids.extend(uid for uid in roommate_profiles if uid not in user_profiles)

    for uid in uids:
        user_data = user_profiles.get(uid, {})
        if user_data and user_data.get("role", "user") != "user":
            continue

        data = dict(user_data)
        for key, value in roommate_profiles.get(uid, {}).items():
            if value is None or value == "" or value == [] or value == {}:
                continue
            data[key] = value
        data["uid"] = uid
        merged[uid] = data

    return merged

def _public_roommate_payload(uid: str, data: dict) -> dict:
    return {
        "uid": uid,
        "name": data.get("name", "ApnaStay user"),
        "age": data.get("age"),
        "gender": data.get("gender", ""),
        "city": data.get("city") or data.get("city_name") or "",
        "locality": (
            data.get("locality")
            or data.get("localities")
            or data.get("location")
            or ""
        ),
        "bio": data.get("bio", ""),
        "occupation": data.get("occupation", ""),
        "budget": data.get("budget", ""),
        "move_in_date": data.get("move_in_date", ""),
        "room_type": data.get("room_type", ""),
        "pg_type": data.get("pg_type", ""),
        "distance": data.get("distance", ""),
        "photo_url": data.get("photo_url", ""),
        "hobbies": data.get("hobbies", data.get("lifestyle_tags", [])),
        "food_preference": data.get("food_preference", ""),
        "food_habit": data.get("food_habit", ""),
        "cleanliness_level": data.get(
            "cleanliness_level", data.get("cleanliness", "")
        ),
        "cleaning_frequency": data.get("cleaning_frequency", ""),
        "sleep_schedule": data.get("sleep_schedule", ""),
        "wake_up_time": data.get("wake_up_time", ""),
        "social_level": data.get("social_level", ""),
        "noise_preference": data.get("noise_preference", ""),
        "weekend_lifestyle": data.get("weekend_lifestyle", ""),
        "study_environment": data.get("study_environment", ""),
        "preferred_personality": data.get("preferred_personality", ""),
        "compatibility_factors": data.get("compatibility_factors", []),
        "college_company": data.get("college_company", ""),
        "course_job": data.get("course_job", ""),
    }


# --------------------------------------------------
# CREATE PROFILE
# --------------------------------------------------

@router.post("/profile")
def create_profile(
    profile: RoommateProfileCreate,
    token: dict = Depends(verify_firebase_token),
):

    uid = token["uid"]

    data = profile.model_dump()

    data["uid"] = uid

    data["created_at"] = datetime.now(
        timezone.utc
    )

    db.collection(
        "roommate_profiles"
    ).document(uid).set(
        data,
        merge=True,
    )

    return {
        "message": "Roommate profile saved",
        "uid": uid,
    }


# --------------------------------------------------
# GET MY PROFILE
# --------------------------------------------------

@router.get("/profile")
def get_profile(
    token: dict = Depends(verify_firebase_token),
):

    uid = token["uid"]

    document = (
        db.collection(
            "roommate_profiles"
        )
        .document(uid)
        .get()
    )

    if not document.exists:

        raise HTTPException(
            status_code=404,
            detail="Roommate profile not found",
        )

    return {
        "uid": uid,
        **document.to_dict(),
    }


# --------------------------------------------------
# UPDATE PROFILE
# --------------------------------------------------

@router.put("/profile")
def update_profile(
    profile: RoommateProfileUpdate,
    token: dict = Depends(verify_firebase_token),
):

    uid = token["uid"]

    data = {
        key: value
        for key, value in profile.model_dump().items()
        if value is not None
    }

    if not data:

        raise HTTPException(
            status_code=400,
            detail="No fields provided",
        )

    db.collection(
        "roommate_profiles"
    ).document(uid).set(
        data,
        merge=True,
    )

    return {
        "message": "Roommate profile updated",
    }


# --------------------------------------------------
# GET OTHER ROOMMATES
# --------------------------------------------------

@router.get("/")
def get_roommates(
    token: dict = Depends(verify_firebase_token),
):
    current_uid = token["uid"]
    profiles = _collect_roommate_profiles()
    roommates = []
    for uid, data in profiles.items():
        if uid == current_uid:
            continue
        roommates.append(_public_roommate_payload(uid, data))
    return roommates


# --------------------------------------------------
# SAVED ROOMMATE DECISIONS
# --------------------------------------------------

def _roommate_decisions(uid: str):
    return (
        db.collection("users")
        .document(uid)
        .collection("roommate_decisions")
    )


@router.post("/decision")
def save_roommate_decision(
    decision: RoommateDecisionRequest,
    token: dict = Depends(verify_firebase_token),
):
    current_uid = token["uid"]
    target_uid = decision.target_uid.strip()
    if not target_uid:
        raise HTTPException(status_code=400, detail="A roommate profile ID is required.")
    if target_uid == current_uid:
        raise HTTPException(status_code=400, detail="You cannot decide on your own profile.")

    _roommate_decisions(current_uid).document(target_uid).set(
        {
            "target_uid": target_uid,
            "decision": decision.decision,
            "updated_at": datetime.now(timezone.utc),
        },
        merge=True,
    )
    return {"target_uid": target_uid, "decision": decision.decision}


@router.get("/decisions")
def get_roommate_decisions(
    token: dict = Depends(verify_firebase_token),
):
    decisions = _roommate_decisions(token["uid"]).stream()
    return [
        {
            "target_uid": document.id,
            "decision": (document.to_dict() or {}).get("decision"),
        }
        for document in decisions
    ]


@router.get("/likes")
def get_liked_roommates(
    token: dict = Depends(verify_firebase_token),
):
    current_uid = token["uid"]
    profiles = _collect_roommate_profiles()
    liked = []
    for document in _roommate_decisions(current_uid).stream():
        data = document.to_dict() or {}
        if data.get("decision") != "like":
            continue
        profile = profiles.get(document.id)
        if profile is not None:
            liked.append(_public_roommate_payload(document.id, profile))
    return liked


# --------------------------------------------------
# ROOMMATE REQUESTS
# --------------------------------------------------

def _roommate_request_id(from_uid: str, to_uid: str) -> str:
    key = f"{from_uid}:{to_uid}".encode("utf-8")
    return hashlib.sha256(key).hexdigest()


def _roommate_request_ref(from_uid: str, to_uid: str):
    request_id = _roommate_request_id(from_uid, to_uid)
    return db.collection("roommate_requests").document(request_id)


@router.post("/requests")
def create_roommate_request(
    request: RoommateRequestCreate,
    token: dict = Depends(verify_firebase_token),
):
    from_uid = token["uid"]
    to_uid = request.target_uid.strip()
    if not to_uid:
        raise HTTPException(status_code=400, detail="A roommate profile ID is required.")
    if to_uid == from_uid:
        raise HTTPException(status_code=400, detail="You cannot request yourself.")
    if to_uid not in _collect_roommate_profiles():
        raise HTTPException(status_code=404, detail="Roommate profile not found.")

    like_ref = _roommate_decisions(from_uid).document(to_uid)
    like = like_ref.get()
    if not like.exists or (like.to_dict() or {}).get("decision") != "like":
        raise HTTPException(status_code=409, detail="Like this profile before sending a roommate request.")

    request_ref = _roommate_request_ref(from_uid, to_uid)
    existing = request_ref.get()
    if existing.exists:
        status = (existing.to_dict() or {}).get("status", "pending")
        if status == "declined":
            raise HTTPException(status_code=409, detail="This roommate request was declined.")
        return {"request_id": request_ref.id, "status": status}

    reverse_request = _roommate_request_ref(to_uid, from_uid).get()
    if reverse_request.exists:
        reverse_status = (reverse_request.to_dict() or {}).get("status", "pending")
        if reverse_status == "accepted":
            return {"request_id": reverse_request.id, "status": "accepted"}
        if reverse_status == "pending":
            raise HTTPException(status_code=409, detail="This person has already sent you a request. Check Roommate Requests.")
        raise HTTPException(status_code=409, detail="A roommate request between you was already declined.")

    now = datetime.now(timezone.utc)
    request_ref.set(
        {
            "request_id": request_ref.id,
            "from_uid": from_uid,
            "to_uid": to_uid,
            "status": "pending",
            "created_at": now,
            "updated_at": now,
        }
    )
    return {"request_id": request_ref.id, "status": "pending"}


@router.get("/requests/status/{target_uid}")
def get_roommate_request_status(
    target_uid: str,
    token: dict = Depends(verify_firebase_token),
):
    current_uid = token["uid"]
    if target_uid == current_uid:
        return {"status": None}
    outgoing = _roommate_request_ref(current_uid, target_uid).get()
    if outgoing.exists:
        data = outgoing.to_dict() or {}
        return {"request_id": outgoing.id, "status": data.get("status")}
    incoming = _roommate_request_ref(target_uid, current_uid).get()
    if incoming.exists:
        data = incoming.to_dict() or {}
        status = data.get("status")
        status = "incoming_pending" if status == "pending" else status
        return {"request_id": incoming.id, "status": status}
    return {"status": None}


@router.get("/requests")
def get_roommate_requests(
    token: dict = Depends(verify_firebase_token),
):
    current_uid = token["uid"]
    profiles = _collect_roommate_profiles()
    records = []
    for field, direction in (("to_uid", "incoming"), ("from_uid", "outgoing")):
        for document in db.collection("roommate_requests").where(field, "==", current_uid).stream():
            data = document.to_dict() or {}
            other_uid = data.get("from_uid") if direction == "incoming" else data.get("to_uid")
            profile = profiles.get(other_uid, {})
            records.append(
                {
                    "request_id": document.id,
                    "direction": direction,
                    "status": data.get("status", "pending"),
                    "created_at": data.get("created_at"),
                    "roommate": _public_roommate_payload(other_uid, profile) if profile else {"uid": other_uid},
                }
            )
    records.sort(key=lambda item: item["created_at"] or datetime.min.replace(tzinfo=timezone.utc), reverse=True)
    return records


@router.post("/requests/{request_id}/respond")
def respond_to_roommate_request(
    request_id: str,
    response: RoommateRequestResponse,
    token: dict = Depends(verify_firebase_token),
):
    current_uid = token["uid"]
    request_ref = db.collection("roommate_requests").document(request_id)
    snapshot = request_ref.get()
    if not snapshot.exists:
        raise HTTPException(status_code=404, detail="Roommate request not found.")
    data = snapshot.to_dict() or {}
    if data.get("to_uid") != current_uid:
        raise HTTPException(status_code=403, detail="Only the recipient can respond to this request.")
    status = "accepted" if response.decision == "accept" else "declined"
    if data.get("status") != "pending":
        if data.get("status") == status:
            return {"request_id": request_id, "status": status}
        raise HTTPException(status_code=409, detail="This roommate request has already been answered.")
    now = datetime.now(timezone.utc)
    batch = db.batch()
    batch.update(request_ref, {"status": status, "updated_at": now})
    if status == "accepted":
        batch.set(
            _roommate_decisions(current_uid).document(data["from_uid"]),
            {
                "target_uid": data["from_uid"],
                "decision": "like",
                "updated_at": now,
            },
            merge=True,
        )
    batch.commit()
    return {"request_id": request_id, "status": status}


# --------------------------------------------------
# ML RECOMMENDATIONS
# --------------------------------------------------

@router.get("/recommendations")
def get_recommended_roommates(
    top_k: int = Query(20, ge=1, le=50),
    token: dict = Depends(verify_firebase_token),
):
    current_uid = token["uid"]
    profiles = _collect_roommate_profiles()
    current = profiles.get(current_uid)

    if current is None:
        raise HTTPException(
            status_code=404,
            detail="Complete your profile before using roommate matching.",
        )

    decided_uids = {
        document.id
        for document in _roommate_decisions(current_uid).stream()
    }
    candidates = [
        _public_roommate_payload(uid, data)
        for uid, data in profiles.items()
        if uid != current_uid and uid not in decided_uids
    ]

    if not candidates:
        return []

    try:
        recommender = get_recommender()
        recommendations = recommender.recommend(
            _public_roommate_payload(current_uid, current),
            candidates,
            top_k=top_k,
        )
    except FileNotFoundError as error:
        raise HTTPException(status_code=503, detail=str(error)) from error
    except Exception as error:
        raise HTTPException(
            status_code=500,
            detail=f"Roommate recommendation failed: {error}",
        ) from error

    return recommendations

