from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException

from app.core.auth import verify_firebase_token
from app.core.firebase import db
from app.schemas.roommate_pg_proposal import (
    RoommatePgProposalCreate,
    RoommatePgProposalDecision,
)


router = APIRouter(prefix="/roommate-pg-proposals", tags=["Roommate PG Proposals"])


def _response(document, uid: str):
    data = document.to_dict() or {}
    data["id"] = document.id
    data["is_recipient"] = data.get("recipient_uid") == uid
    return data


@router.post("/")
def create_roommate_pg_proposal(
    proposal: RoommatePgProposalCreate,
    token: dict = Depends(verify_firebase_token),
):
    uid = token["uid"]
    match_doc = db.collection("roommate_requests").document(proposal.match_request_id).get()
    if not match_doc.exists:
        raise HTTPException(status_code=404, detail="Roommate match not found.")
    match = match_doc.to_dict() or {}
    members = {match.get("from_uid"), match.get("to_uid")}
    if match.get("status") != "accepted" or uid not in members or len(members) != 2:
        raise HTTPException(status_code=403, detail="Accept the roommate request before choosing a PG together.")
    recipient_uid = next(member for member in members if member != uid)

    pg_doc = db.collection("pg_listings").document(proposal.pg_id).get()
    if not pg_doc.exists:
        raise HTTPException(status_code=404, detail="PG not found.")
    pg = pg_doc.to_dict() or {}
    owner_uid = pg.get("owner_id")
    if not owner_uid:
        raise HTTPException(status_code=409, detail="This PG has no assigned owner.")
    if owner_uid in members:
        raise HTTPException(status_code=400, detail="A PG owner cannot book their own listing.")
    if pg.get("is_available") is not True:
        raise HTTPException(status_code=400, detail="This PG is currently unavailable.")

    active = {"awaiting_roommate", "sent_to_owner"}
    for existing in db.collection("roommate_pg_proposals").where("match_request_id", "==", proposal.match_request_id).stream():
        if (existing.to_dict() or {}).get("status") in active:
            raise HTTPException(status_code=409, detail="A PG proposal or booking for this match is already active.")

    proposer = db.collection("users").document(uid).get().to_dict() or {}
    recipient = db.collection("users").document(recipient_uid).get().to_dict() or {}
    owner = db.collection("users").document(owner_uid).get().to_dict() or {}
    now = datetime.now(timezone.utc)
    data = {
        "match_request_id": proposal.match_request_id,
        "proposer_uid": uid,
        "recipient_uid": recipient_uid,
        "proposer_name": proposer.get("name", "ApnaStay user"),
        "recipient_name": recipient.get("name", "Your roommate"),
        "pg_id": proposal.pg_id,
        "pg_name": pg.get("name", "PG"),
        "pg_locality": pg.get("locality", ""),
        "pg_city": pg.get("city", ""),
        "pg_image_url": pg.get("image_url", ""),
        "pg_image_urls": pg.get("image_urls", []),
        "amount": float(pg.get("price") or 0),
        "room_type": proposal.room_type or pg.get("room_type", ""),
        "duration": proposal.duration,
        "move_in_date": proposal.move_in_date,
        "pg_owner_id": owner_uid,
        "owner_name": owner.get("name", pg.get("owner_name", "PG Owner")),
        "status": "awaiting_roommate",
        "created_at": now,
        "updated_at": now,
    }
    document = db.collection("roommate_pg_proposals").document()
    document.set(data)
    return {"id": document.id, "status": data["status"]}


@router.get("/my")
def get_my_roommate_pg_proposals(token: dict = Depends(verify_firebase_token)):
    uid = token["uid"]
    collection = db.collection("roommate_pg_proposals")
    unique = {}
    for field in ("proposer_uid", "recipient_uid"):
        for document in collection.where(field, "==", uid).stream():
            unique[document.id] = document
    results = [_response(document, uid) for document in unique.values()]
    results.sort(key=lambda item: str(item.get("created_at", "")), reverse=True)
    return results


@router.patch("/{proposal_id}")
def decide_roommate_pg_proposal(
    proposal_id: str,
    decision: RoommatePgProposalDecision,
    token: dict = Depends(verify_firebase_token),
):
    uid = token["uid"]
    proposal_ref = db.collection("roommate_pg_proposals").document(proposal_id)
    proposal_doc = proposal_ref.get()
    if not proposal_doc.exists:
        raise HTTPException(status_code=404, detail="PG proposal not found.")
    proposal = proposal_doc.to_dict() or {}
    if proposal.get("recipient_uid") != uid:
        raise HTTPException(status_code=403, detail="Only the matched roommate can respond.")
    status = proposal.get("status")
    if status != "awaiting_roommate":
        expected = "sent_to_owner" if decision.decision == "accepted" else "roommate_declined"
        if status == expected:
            return {"status": status, "booking_id": proposal.get("booking_id")}
        raise HTTPException(status_code=409, detail="This PG proposal has already been answered.")

    now = datetime.now(timezone.utc)
    if decision.decision == "declined":
        proposal_ref.update({"status": "roommate_declined", "updated_at": now})
        return {"status": "roommate_declined"}

    pg_doc = db.collection("pg_listings").document(proposal["pg_id"]).get()
    if not pg_doc.exists or (pg_doc.to_dict() or {}).get("is_available") is not True:
        raise HTTPException(status_code=409, detail="This PG is no longer available.")
    proposer_uid = proposal["proposer_uid"]
    proposer = db.collection("users").document(proposer_uid).get().to_dict() or {}
    owner_uid = proposal["pg_owner_id"]
    owner = db.collection("users").document(owner_uid).get().to_dict() or {}
    booking_ref = db.collection("bookings").document()
    booking_data = {
        "pg_id": proposal["pg_id"],
        "pg_name": proposal.get("pg_name", "PG"),
        "user_id": proposer_uid,
        "user_name": proposer.get("name", "ApnaStay user"),
        "user_email": proposer.get("email", ""),
        "user_photo_url": proposer.get("photo_url", ""),
        "applicant_ids": [proposer_uid, uid],
        "pg_owner_id": owner_uid,
        "owner_name": owner.get("name", proposal.get("owner_name", "PG Owner")),
        "roommate_proposal_id": proposal_doc.id,
        "duration": proposal.get("duration", "1 Month"),
        "move_in_date": proposal.get("move_in_date"),
        "room_type": proposal.get("room_type"),
        "amount": proposal.get("amount", 0),
        "status": "pending",
        "created_at": now,
    }
    batch = db.batch()
    batch.set(booking_ref, booking_data)
    batch.update(proposal_ref, {"status": "sent_to_owner", "booking_id": booking_ref.id, "updated_at": now})
    batch.commit()
    return {"status": "sent_to_owner", "booking_id": booking_ref.id}
