import os
from pathlib import Path

from dotenv import load_dotenv
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile

from app.core.auth import verify_firebase_token
from app.core.firebase import db


BACKEND_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(BACKEND_ROOT / ".env")

import cloudinary
import cloudinary.uploader

_cloudinary_url = os.getenv("CLOUDINARY_URL")
_cloudinary_parts = (
    os.getenv("CLOUDINARY_CLOUD_NAME"),
    os.getenv("CLOUDINARY_API_KEY"),
    os.getenv("CLOUDINARY_API_SECRET"),
)
_cloudinary_configured = bool(_cloudinary_url) or all(_cloudinary_parts)

if _cloudinary_url:
    cloudinary.config(secure=True)
elif all(_cloudinary_parts):
    cloudinary.config(
        cloud_name=_cloudinary_parts[0],
        api_key=_cloudinary_parts[1],
        api_secret=_cloudinary_parts[2],
        secure=True,
    )

router = APIRouter(prefix="/media", tags=["Media"])

MAX_IMAGE_BYTES = 10 * 1024 * 1024
MAX_VIDEO_BYTES = 100 * 1024 * 1024
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "application/octet-stream",
}
ALLOWED_VIDEO_CONTENT_TYPES = {
    "video/mp4",
    "video/quicktime",
    "video/webm",
    "video/x-m4v",
    "application/octet-stream",
}

USER_IMAGE_FIELDS = {
    "profile_photo": ("photo_url", False, None),
    "owner_photo": ("owner_photo_url", False, "pg_owner"),
    "provider_photo": ("provider_photo_url", False, "meal_provider"),
    "kitchen_photo": ("kitchen_photo_urls", True, "meal_provider"),
    "menu_photo": ("menu_photo_urls", True, "meal_provider"),
}


@router.post("/upload")
def upload_image(
    image: UploadFile = File(...),
    category: str = Form(...),
    pg_id: str | None = Form(default=None),
    token: dict = Depends(verify_firebase_token),
):
    if not _cloudinary_configured:
        raise HTTPException(
            status_code=503,
            detail=(
                "Cloudinary is not configured. Add CLOUDINARY_URL or all three "
                "variables CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, and "
                "CLOUDINARY_API_SECRET to backend/.env, then restart FastAPI."
            ),
        )

    if image.content_type not in ALLOWED_CONTENT_TYPES:
        raise HTTPException(status_code=415, detail="Upload a JPG, PNG, or WebP image.")

    image.file.seek(0, os.SEEK_END)
    image_size = image.file.tell()
    image.file.seek(0)
    if image_size == 0:
        raise HTTPException(status_code=400, detail="The image is empty.")
    if image_size > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=413, detail="Image must be 10 MB or smaller.")

    uid = token["uid"]
    user_ref = None
    pg_ref = None

    if category in USER_IMAGE_FIELDS:
        user_ref = db.collection("users").document(uid)
        user_doc = user_ref.get()
        if not user_doc.exists:
            raise HTTPException(status_code=404, detail="User profile not found.")
        _, _, required_role = USER_IMAGE_FIELDS[category]
        if required_role and (user_doc.to_dict() or {}).get("role") != required_role:
            raise HTTPException(
                status_code=403,
                detail=f"This image type requires the {required_role} role.",
            )
    elif category == "pg_room":
        owner_ref = db.collection("users").document(uid)
        owner_doc = owner_ref.get()
        if not owner_doc.exists:
            raise HTTPException(status_code=404, detail="User profile not found.")
        if (owner_doc.to_dict() or {}).get("role") != "pg_owner":
            raise HTTPException(status_code=403, detail="PG photos can only be uploaded by PG owners.")
        if pg_id:
            pg_ref = db.collection("pg_listings").document(pg_id)
            pg_doc = pg_ref.get()
            if not pg_doc.exists:
                raise HTTPException(status_code=404, detail="PG listing not found.")
            if (pg_doc.to_dict() or {}).get("owner_id") != uid:
                raise HTTPException(status_code=403, detail="You can only upload photos for your own PG.")
    else:
        raise HTTPException(status_code=400, detail="Unsupported image category.")

    folder = (
        f"apnastay/pgs/{uid}/{pg_id or 'pending'}"
        if category == "pg_room"
        else f"apnastay/users/{uid}/{category}"
    )

    try:
        upload_result = cloudinary.uploader.upload(
            image.file,
            folder=folder,
            resource_type="image",
            allowed_formats=["jpg", "jpeg", "png", "webp"],
            timeout=45,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail="Cloudinary could not upload the image.") from exc

    image_url = upload_result.get("secure_url")
    if not image_url:
        raise HTTPException(status_code=502, detail="Cloudinary did not return a secure image URL.")

    saved_to_firestore = False
    try:
        if user_ref:
            field, append_to_list, _ = USER_IMAGE_FIELDS[category]
            current_data = user_ref.get().to_dict() or {}
            if append_to_list:
                urls = current_data.get(field, [])
                if not isinstance(urls, list):
                    urls = []
                if image_url not in urls:
                    urls.append(image_url)
                user_ref.update({field: urls})
            else:
                user_ref.update({field: image_url})
            saved_to_firestore = True
        elif pg_ref:
            pg_data = pg_ref.get().to_dict() or {}
            urls = pg_data.get("image_urls", [])
            if not isinstance(urls, list):
                urls = []
            if image_url not in urls:
                urls.append(image_url)
            updates = {"image_urls": urls}
            if not pg_data.get("image_url"):
                updates["image_url"] = image_url
            pg_ref.update(updates)
            saved_to_firestore = True
    except Exception as exc:
        try:
            cloudinary.uploader.destroy(upload_result["public_id"], resource_type="image")
        except Exception:
            pass
        raise HTTPException(status_code=502, detail="The image uploaded, but its URL could not be saved.") from exc

    return {
        "url": image_url,
        "public_id": upload_result.get("public_id"),
        "category": category,
        "saved_to_firestore": saved_to_firestore,
    }


@router.post("/upload-video")
def upload_pg_video(
    video: UploadFile = File(...),
    category: str = Form(default="pg_video"),
    pg_id: str | None = Form(default=None),
    token: dict = Depends(verify_firebase_token),
):
    if not _cloudinary_configured:
        raise HTTPException(
            status_code=503,
            detail="Cloudinary is not configured. Add its credentials to backend/.env and restart FastAPI.",
        )
    if category != "pg_video":
        raise HTTPException(status_code=400, detail="Unsupported video category.")
    if video.content_type not in ALLOWED_VIDEO_CONTENT_TYPES:
        raise HTTPException(status_code=415, detail="Upload an MP4, MOV, or WebM video.")

    video.file.seek(0, os.SEEK_END)
    video_size = video.file.tell()
    video.file.seek(0)
    if video_size == 0:
        raise HTTPException(status_code=400, detail="The video is empty.")
    if video_size > MAX_VIDEO_BYTES:
        raise HTTPException(status_code=413, detail="Video must be 100 MB or smaller.")

    uid = token["uid"]
    owner_doc = db.collection("users").document(uid).get()
    if not owner_doc.exists or (owner_doc.to_dict() or {}).get("role") != "pg_owner":
        raise HTTPException(status_code=403, detail="PG videos can only be uploaded by PG owners.")

    pg_ref = None
    if pg_id:
        pg_ref = db.collection("pg_listings").document(pg_id)
        pg_doc = pg_ref.get()
        if not pg_doc.exists:
            raise HTTPException(status_code=404, detail="PG listing not found.")
        if (pg_doc.to_dict() or {}).get("owner_id") != uid:
            raise HTTPException(status_code=403, detail="You can only upload videos for your own PG.")

    try:
        upload_result = cloudinary.uploader.upload(
            video.file,
            folder=f"apnastay/pgs/{uid}/{pg_id or 'pending'}/videos",
            resource_type="video",
            allowed_formats=["mp4", "mov", "webm", "m4v"],
            timeout=120,
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail="Cloudinary could not upload the video.") from exc

    video_url = upload_result.get("secure_url")
    if not video_url:
        raise HTTPException(status_code=502, detail="Cloudinary did not return a secure video URL.")

    saved_to_firestore = False
    if pg_ref:
        try:
            pg_data = pg_ref.get().to_dict() or {}
            urls = pg_data.get("video_urls", [])
            if not isinstance(urls, list):
                urls = []
            if video_url not in urls:
                urls.append(video_url)
            pg_ref.update({"video_urls": urls})
            saved_to_firestore = True
        except Exception as exc:
            try:
                cloudinary.uploader.destroy(upload_result["public_id"], resource_type="video")
            except Exception:
                pass
            raise HTTPException(status_code=502, detail="The video uploaded, but its URL could not be saved.") from exc

    return {
        "url": video_url,
        "public_id": upload_result.get("public_id"),
        "category": category,
        "saved_to_firestore": saved_to_firestore,
    }
