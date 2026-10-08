from pydantic import BaseModel, Field
from typing import Optional, List


class PGCreate(BaseModel):

    name: str

    locality: str

    city: str = "Mumbai"

    price: float

    gender: Optional[str] = None

    rating: float = 0

    review_count: int = 0

    image_url: Optional[str] = None

    image_urls: List[str] = Field(default_factory=list)

    video_urls: List[str] = Field(default_factory=list)

    address: Optional[str] = None
    security_deposit: Optional[float] = None
    available_beds: Optional[int] = None
    available_from: Optional[str] = None
    pg_type: Optional[str] = None
    bathroom_type: Optional[str] = None
    furnishing: Optional[str] = None
    rules: dict = Field(default_factory=dict)
    owner_identity_verified: bool = False
    property_verified: bool = False

    amenities: List[str] = Field(
        default_factory=list
    )

    room_type: Optional[str] = None

    is_verified: bool = False

    is_available: bool = True


class PGUpdate(BaseModel):

    name: Optional[str] = None

    locality: Optional[str] = None

    city: Optional[str] = None

    price: Optional[float] = None

    gender: Optional[str] = None

    rating: Optional[float] = None

    review_count: Optional[int] = None

    image_url: Optional[str] = None

    image_urls: Optional[List[str]] = None

    video_urls: Optional[List[str]] = None

    address: Optional[str] = None
    security_deposit: Optional[float] = None
    available_beds: Optional[int] = None
    available_from: Optional[str] = None
    pg_type: Optional[str] = None
    bathroom_type: Optional[str] = None
    furnishing: Optional[str] = None
    rules: Optional[dict] = None
    owner_identity_verified: Optional[bool] = None
    property_verified: Optional[bool] = None

    amenities: Optional[List[str]] = None

    room_type: Optional[str] = None

    is_verified: Optional[bool] = None

    is_available: Optional[bool] = None