import re
from typing import List, Literal, Optional

from pydantic import BaseModel, field_validator


UserRole = Literal["user", "pg_owner", "meal_provider"]


class UserCreate(BaseModel):
    name: str
    email: str
    phone: str
    password: str
    age: Optional[int] = None
    gender: Optional[str] = None
    role: UserRole = "user"

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: str) -> str:
        trimmed = value.strip()
        if not trimmed:
            raise ValueError("Name is required.")
        return trimmed

    @field_validator("email")
    @classmethod
    def validate_email(cls, value: str) -> str:
        trimmed = value.strip()
        if "@" not in trimmed or trimmed.count("@") != 1:
            raise ValueError("Email must contain a valid @ format.")
        local_part, domain = trimmed.split("@", 1)
        if not local_part or not domain or "." not in domain:
            raise ValueError("Email must contain a valid domain.")
        return trimmed

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, value: str) -> str:
        digits = re.sub(r"\D", "", value)
        if len(digits) != 10:
            raise ValueError("Phone number must contain exactly 10 digits.")
        return digits

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: str) -> str:
        if len(value) < 8:
            raise ValueError("Password must be at least 8 characters long.")
        if not re.search(r"[A-Z]", value):
            raise ValueError("Password must contain at least one uppercase letter.")
        if not re.search(r"[a-z]", value):
            raise ValueError("Password must contain at least one lowercase letter.")
        if not re.search(r"\d", value):
            raise ValueError("Password must contain at least one number.")
        if not re.search(r"[^A-Za-z0-9]", value):
            raise ValueError("Password must contain at least one special character.")
        return value


class UserUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    password: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    bio: Optional[str] = None
    photo_url: Optional[str] = None
    owner_photo_url: Optional[str] = None
    owner_identity_verified: Optional[bool] = None
    provider_name: Optional[str] = None
    provider_photo_url: Optional[str] = None
    kitchen_address: Optional[str] = None
    kitchen_city: Optional[str] = None
    kitchen_locality: Optional[str] = None
    food_type: Optional[str] = None
    meal_categories: Optional[List[str]] = None
    cuisine_type: Optional[str] = None
    daily_capacity: Optional[int] = None
    price_per_meal: Optional[str] = None
    weekly_plan_price: Optional[str] = None
    monthly_plan_price: Optional[str] = None
    delivery_areas: Optional[str] = None
    delivery_timings: Optional[str] = None
    delivery_charges: Optional[str] = None
    kitchen_photo_urls: Optional[List[str]] = None
    menu_photo_urls: Optional[List[str]] = None
    fssai_license: Optional[str] = None
    hygiene_verified: Optional[bool] = None
    city: Optional[str] = None
    localities: Optional[str] = None
    budget: Optional[str] = None
    move_in_date: Optional[str] = None
    room_type: Optional[str] = None
    pg_type: Optional[str] = None
    distance: Optional[str] = None
    food_preference: Optional[str] = None
    food_habit: Optional[str] = None
    cleanliness_level: Optional[str] = None
    cleaning_frequency: Optional[str] = None
    sleep_schedule: Optional[str] = None
    wake_up_time: Optional[str] = None
    noise_preference: Optional[str] = None
    social_level: Optional[str] = None
    weekend_lifestyle: Optional[str] = None
    hobbies: Optional[List[str]] = None
    occupation: Optional[str] = None
    college_company: Optional[str] = None
    course_job: Optional[str] = None
    study_environment: Optional[str] = None
    preferred_personality: Optional[str] = None
    compatibility_factors: Optional[List[str]] = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        trimmed = value.strip()
        if not trimmed:
            raise ValueError("Name cannot be empty.")
        return trimmed

    @field_validator("email")
    @classmethod
    def validate_email(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        trimmed = value.strip()
        if "@" not in trimmed or trimmed.count("@") != 1:
            raise ValueError("Email must contain a valid @ format.")
        local_part, domain = trimmed.split("@", 1)
        if not local_part or not domain or "." not in domain:
            raise ValueError("Email must contain a valid domain.")
        return trimmed

    @field_validator("phone")
    @classmethod
    def validate_phone(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        digits = re.sub(r"\D", "", value)
        if len(digits) != 10:
            raise ValueError("Phone number must contain exactly 10 digits.")
        return digits

    @field_validator("password")
    @classmethod
    def validate_password(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return value
        if len(value) < 8:
            raise ValueError("Password must be at least 8 characters long.")
        if not re.search(r"[A-Z]", value):
            raise ValueError("Password must contain at least one uppercase letter.")
        if not re.search(r"[a-z]", value):
            raise ValueError("Password must contain at least one lowercase letter.")
        if not re.search(r"\d", value):
            raise ValueError("Password must contain at least one number.")
        if not re.search(r"[^A-Za-z0-9]", value):
            raise ValueError("Password must contain at least one special character.")
        return value

