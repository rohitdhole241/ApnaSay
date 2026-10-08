from fastapi import APIRouter

from app.core.firebase import db


router = APIRouter(
    prefix="/meal-providers",
    tags=["Meal Providers"],
)


@router.get("/")
def get_meal_providers():
    """Return public listing fields for meal providers saved in users."""
    documents = (
        db.collection("users")
        .where("role", "==", "meal_provider")
        .stream()
    )

    public_fields = (
        "provider_photo_url",
        "kitchen_city",
        "kitchen_locality",
        "food_type",
        "meal_categories",
        "cuisine_type",
        "daily_capacity",
        "price_per_meal",
        "weekly_plan_price",
        "monthly_plan_price",
        "delivery_areas",
        "delivery_timings",
        "delivery_charges",
        "kitchen_photo_urls",
        "menu_photo_urls",
        "hygiene_verified",
    )

    providers = []
    for document in documents:
        data = document.to_dict() or {}
        provider_name = data.get("provider_name") or data.get("name")
        if not provider_name:
            continue

        provider = {
            "uid": document.id,
            "provider_name": provider_name,
        }
        provider.update(
            {
                field: data[field]
                for field in public_fields
                if field in data and data[field] is not None
            }
        )
        providers.append(provider)

    return sorted(providers, key=lambda provider: provider["provider_name"].lower())
