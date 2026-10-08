from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routes.users import router as users_router
from app.routes.pg import router as pg_router
from app.routes.roommate import router as roommate_router
from app.routes.roommate_pg_proposals import router as roommate_pg_proposals_router
from app.routes.bookings import router as bookings_router
from app.routes.meal_providers import router as meal_providers_router
from app.routes.meal_bookings import router as meal_bookings_router
from app.routes.media import router as media_router


app = FastAPI(
    title="ApnaStay API",
    description="Backend API for ApnaStay Flutter Application",
    version="1.0.0",
)


# --------------------------------------------------
# CORS
# --------------------------------------------------

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --------------------------------------------------
# Routes
# --------------------------------------------------

app.include_router(users_router)
app.include_router(pg_router)
app.include_router(roommate_router)
app.include_router(roommate_pg_proposals_router)
app.include_router(bookings_router)
app.include_router(meal_providers_router)
app.include_router(meal_bookings_router)
app.include_router(media_router)


# --------------------------------------------------
# Root
# --------------------------------------------------

@app.get("/")
def root():
    return {
        "message": "Welcome to ApnaStay API",
        "status": "running",
        "version": "1.0.0",
    }


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "service": "ApnaStay API",
    }
