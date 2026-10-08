from typing import Literal, Optional

from pydantic import BaseModel, Field


class BookingCreate(BaseModel):
    pg_id: str
    move_in_date: Optional[str] = None
    duration: Literal["1 Month", "3 Months", "6 Months", "12 Months"]
    room_type: Optional[str] = None
    amount: float = Field(default=0, ge=0)


class BookingUpdate(BaseModel):
    status: Literal["accepted", "declined", "cancelled"]
