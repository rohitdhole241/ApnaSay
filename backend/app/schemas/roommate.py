from pydantic import BaseModel, Field
from typing import Literal, Optional, List


class RoommateDecisionRequest(BaseModel):
    target_uid: str = Field(min_length=1, max_length=128)
    decision: Literal["like", "pass"]


class RoommateRequestCreate(BaseModel):
    target_uid: str = Field(min_length=1, max_length=128)


class RoommateRequestResponse(BaseModel):
    decision: Literal["accept", "decline"]


class RoommateProfileCreate(BaseModel):

    name: str

    age: Optional[int] = None

    gender: Optional[str] = None

    city: str = "Mumbai"

    locality: Optional[str] = None

    bio: Optional[str] = None

    lifestyle_tags: List[str] = Field(
        default_factory=list
    )

    food_preference: Optional[str] = None

    cleanliness: Optional[str] = None

    sleep_schedule: Optional[str] = None


class RoommateProfileUpdate(BaseModel):

    name: Optional[str] = None

    age: Optional[int] = None

    gender: Optional[str] = None

    city: Optional[str] = None

    locality: Optional[str] = None

    bio: Optional[str] = None

    lifestyle_tags: Optional[List[str]] = None

    food_preference: Optional[str] = None

    cleanliness: Optional[str] = None

    sleep_schedule: Optional[str] = None