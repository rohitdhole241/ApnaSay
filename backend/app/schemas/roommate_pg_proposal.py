from typing import Literal, Optional

from pydantic import BaseModel


class RoommatePgProposalCreate(BaseModel):
    match_request_id: str
    pg_id: str
    duration: Literal["1 Month", "3 Months", "6 Months", "12 Months"] = "1 Month"
    move_in_date: Optional[str] = None
    room_type: Optional[str] = None


class RoommatePgProposalDecision(BaseModel):
    decision: Literal["accepted", "declined"]
