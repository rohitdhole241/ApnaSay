from datetime import datetime, timezone

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
)

from app.core.firebase import db
from app.core.auth import verify_firebase_token

from app.schemas.pg import (
    PGCreate,
    PGUpdate,
)


router = APIRouter(
    prefix="/pg",
    tags=["PG Listings"],
)


def _listing_response(document):
    data = document.to_dict()
    owner_id = data.get("owner_id")
    if owner_id:
        owner_document = db.collection("users").document(owner_id).get()
        owner_data = owner_document.to_dict() or {}
        data["owner_name"] = data.get("owner_name") or owner_data.get("name", "PG Owner")
        data["owner_photo_url"] = (
            owner_data.get("owner_photo_url")
            or owner_data.get("photo_url")
            or data.get("owner_photo_url", "")
        )

    return {
        "id": document.id,
        **data,
    }


# --------------------------------------------------
# GET ALL PGs
# --------------------------------------------------

@router.get("/")
def get_all_pgs():

    documents = (
        db.collection("pg_listings")
        .where(
            "is_available",
            "==",
            True,
        )
        .stream()
    )

    pgs = []

    for document in documents:

        pgs.append(_listing_response(document))

    return pgs


# --------------------------------------------------
# GET PG BY ID
# --------------------------------------------------

@router.get("/mine")
def get_my_pgs(
    token: dict = Depends(verify_firebase_token),
):
    documents = (
        db.collection("pg_listings")
        .where("owner_id", "==", token["uid"])
        .stream()
    )

    return [_listing_response(document) for document in documents]

@router.get("/{pg_id}")
def get_pg(pg_id: str):

    document = (
        db.collection("pg_listings")
        .document(pg_id)
        .get()
    )

    if not document.exists:

        raise HTTPException(
            status_code=404,
            detail="PG not found",
        )

    return _listing_response(document)


# --------------------------------------------------
# CREATE PG
# --------------------------------------------------

@router.post("/")
def create_pg(
    pg: PGCreate,
    token: dict = Depends(verify_firebase_token),
):

    data = pg.model_dump()

    data["owner_id"] = token["uid"]

    owner_document = db.collection("users").document(token["uid"]).get()
    owner_data = owner_document.to_dict() or {}
    data["owner_name"] = owner_data.get("name", "PG Owner")
    data["owner_photo_url"] = owner_data.get("owner_photo_url") or owner_data.get("photo_url", "")

    data["created_at"] = datetime.now(
        timezone.utc
    )

    document = (
        db.collection("pg_listings")
        .document()
    )

    document.set(data)

    return {
        "message": "PG created successfully",
        "id": document.id,
    }


# --------------------------------------------------
# UPDATE PG
# --------------------------------------------------

@router.put("/{pg_id}")
def update_pg(
    pg_id: str,
    pg: PGUpdate,
    token: dict = Depends(verify_firebase_token),
):

    document_ref = (
        db.collection("pg_listings")
        .document(pg_id)
    )

    document = document_ref.get()

    if not document.exists:

        raise HTTPException(
            status_code=404,
            detail="PG not found",
        )

    existing = document.to_dict()

    if existing.get("owner_id") != token["uid"]:

        raise HTTPException(
            status_code=403,
            detail="You are not the owner of this PG",
        )

    data = {
        key: value
        for key, value in pg.model_dump().items()
        if value is not None
    }

    document_ref.update(data)

    return {
        "message": "PG updated successfully",
    }


# --------------------------------------------------
# DELETE PG
# --------------------------------------------------

@router.delete("/{pg_id}")
def delete_pg(
    pg_id: str,
    token: dict = Depends(verify_firebase_token),
):

    document_ref = (
        db.collection("pg_listings")
        .document(pg_id)
    )

    document = document_ref.get()

    if not document.exists:

        raise HTTPException(
            status_code=404,
            detail="PG not found",
        )

    existing = document.to_dict()

    if existing.get("owner_id") != token["uid"]:

        raise HTTPException(
            status_code=403,
            detail="You are not the owner of this PG",
        )

    document_ref.delete()

    return {
        "message": "PG deleted successfully",
    }