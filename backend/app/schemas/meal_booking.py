from typing import Literal, Optional

from pydantic import BaseModel, Field


class MealBookingCreate(BaseModel):
    provider_uid: str = Field(min_length=1, max_length=128)
    service_plan: str = Field(min_length=1, max_length=100)
    amount: float = Field(ge=0)
    delivery_address: str = Field(min_length=5, max_length=500)
    notes: Optional[str] = Field(default=None, max_length=500)


class MealBookingUpdate(BaseModel):
    status: Literal["accepted", "declined"]
