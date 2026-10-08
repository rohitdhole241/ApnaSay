from __future__ import annotations

import argparse
import csv
import random
from datetime import date, timedelta
from pathlib import Path
from typing import Dict, List


SEED = 23101
random.seed(SEED)

CITIES = {
    "Mumbai": [
        "Andheri", "Powai", "Ghatkopar", "Bandra", "Vikhroli", "Kurla", "Mulund", "Dadar", "Thane", "Kalyan"
    ],
    "Pune": ["Viman Nagar", "Kothrud", "Hinjewadi", "Baner", "Wakad", "Aundh"],
    "Bengaluru": ["Koramangala", "Whitefield", "HSR Layout", "Indiranagar", "Marathahalli"],
    "Hyderabad": ["Madhapur", "Gachibowli", "Kondapur", "Kukatpally", "Banjara Hills"],
    "Navi Mumbai": ["Vashi", "Nerul", "Belapur", "Airoli", "Kharghar"],
}

HOBBIES = ["Music", "Sports", "Gaming", "Reading", "Travel", "Cooking"]
FACTORS = ["Cleanliness", "Budget", "Sleep schedule", "Food", "Privacy", "Location"]
FOOD_PREFS = ["No preference", "Vegetarian", "Non-vegetarian", "Eggetarian"]
FOOD_HABITS = ["No preference", "Home-cooked", "Dabbas", "I cook"]
CLEANLINESS = ["Relaxed", "Balanced", "Very particular"]
CLEANING = ["Daily", "Weekly", "When needed"]
SLEEP = ["Early sleeper", "Flexible", "Night owl"]
WAKE = ["Before 7 AM", "7-9 AM", "After 9 AM"]
NOISE = ["Quiet", "Moderate", "Lively"]
SOCIAL = ["Introvert", "Balanced", "Very social"]
WEEKEND = ["Mostly at home", "Mix of both", "Out and about"]
OCCUPATION = ["Student", "Working professional", "Entrepreneur", "Other"]
STUDY = ["Quiet", "Collaborative", "Flexible"]
PERSONALITY = ["Easy-going", "Organized", "Outgoing", "Quiet"]
ROOM_TYPES = ["Any room", "Single", "Double sharing", "Triple sharing"]
PG_TYPES = ["Any PG", "Boys PG", "Girls PG", "Co-living"]
DISTANCES = ["Up to 2 km", "Up to 5 km", "Up to 10 km"]
COURSES = ["B.Tech Information Technology", "B.Tech Computer Engineering", "MBA", "Design", "Finance", "Software Engineering", "Marketing", "Data Analytics"]
NAMES = ["Aarav", "Vivaan", "Aditya", "Arjun", "Rohan", "Rahul", "Karan", "Kabir", "Yash", "Aman", "Neha", "Sneha", "Priya", "Ananya", "Isha", "Riya", "Aditi", "Meera", "Pooja", "Kavya", "Sanya", "Tanvi", "Nikhil", "Siddharth", "Varun", "Om", "Dev", "Manav", "Sakshi", "Simran"]


def weighted_choice(values: List[str], weights: List[float] | None = None) -> str:
    return random.choices(values, weights=weights, k=1)[0]


def make_profile(i: int) -> Dict[str, object]:
    city = weighted_choice(list(CITIES), [0.48, 0.17, 0.15, 0.10, 0.10])
    occupation = weighted_choice(OCCUPATION, [0.58, 0.32, 0.06, 0.04])
    age = random.randint(18, 26) if occupation == "Student" else random.randint(22, 34)
    if city == "Mumbai":
        base = random.randint(6500, 18000)
    elif city == "Bengaluru":
        base = random.randint(7000, 19000)
    elif city == "Pune":
        base = random.randint(5500, 15000)
    else:
        base = random.randint(5000, 14000)
    budget = int(round(base / 250) * 250)
    locality = random.choice(CITIES[city])
    nearby = random.sample(CITIES[city], k=min(len(CITIES[city]), random.randint(1, 3)))
    if locality not in nearby:
        nearby[0] = locality
    move_in = date.today() + timedelta(days=random.randint(7, 120))
    hobbies = random.sample(HOBBIES, k=random.randint(1, 3))
    factors = random.sample(FACTORS, k=random.randint(1, 3))
    bio_templates = [
        "{} who enjoys {} and prefers a {} home routine.",
        "{} looking for a comfortable shared stay; into {} and values {}.",
        "{} and {}-focused, usually spends weekends {}.",
    ]
    cleanliness = weighted_choice(CLEANLINESS, [0.25, 0.50, 0.25])
    sleep = weighted_choice(SLEEP, [0.28, 0.44, 0.28])
    social = weighted_choice(SOCIAL, [0.28, 0.44, 0.28])
    weekend = weighted_choice(WEEKEND, [0.32, 0.46, 0.22])
    study = weighted_choice(STUDY, [0.40, 0.28, 0.32])
    course = weighted_choice(COURSES, [0.25, 0.15, 0.08, 0.06, 0.05, 0.16, 0.10, 0.15])
    college_company = random.choice([
        "VIT Mumbai", "Mumbai University", "Pune University", "Private Tech Company", "Startup", "Design Institute", "Business School"
    ])
    bio = random.choice(bio_templates).format(
        occupation.lower(),
        ", ".join(hobbies[:2]),
        cleanliness.lower(),
    )
    return {
        "user_id": f"dummy_{i:05d}",
        "name": f"{random.choice(NAMES)} {random.choice(["Sharma", "Patil", "Mehta", "Kulkarni", "Shah", "Joshi", "Gupta", "Singh"])}",
        "age": age,
        "gender": random.choice(["Male", "Female", "Non-binary"]),
        "city": city,
        "localities": ", ".join(nearby),
        "budget": str(budget),
        "move_in_date": move_in.isoformat(),
        "room_type": weighted_choice(ROOM_TYPES, [0.25, 0.20, 0.40, 0.15]),
        "pg_type": weighted_choice(PG_TYPES, [0.30, 0.20, 0.20, 0.30]),
        "distance": weighted_choice(DISTANCES, [0.20, 0.55, 0.25]),
        "food_preference": weighted_choice(FOOD_PREFS, [0.15, 0.40, 0.30, 0.15]),
        "food_habit": weighted_choice(FOOD_HABITS, [0.20, 0.42, 0.20, 0.18]),
        "cleanliness_level": cleanliness,
        "cleaning_frequency": weighted_choice(CLEANING, [0.30, 0.52, 0.18]),
        "sleep_schedule": sleep,
        "wake_up_time": weighted_choice(WAKE, [0.28, 0.52, 0.20]),
        "noise_preference": weighted_choice(NOISE, [0.34, 0.46, 0.20]),
        "social_level": social,
        "weekend_lifestyle": weekend,
        "hobbies": ", ".join(hobbies),
        "occupation": occupation,
        "college_company": college_company,
        "course_job": course,
        "study_environment": study,
        "preferred_personality": weighted_choice(PERSONALITY, [0.38, 0.20, 0.22, 0.20]),
        "compatibility_factors": ", ".join(factors),
        "bio": bio,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rows", type=int, default=5000)
    parser.add_argument("--output", default=str(Path(__file__).resolve().parent / "data" / "roommate_profiles_dummy.csv"))
    args = parser.parse_args()
    rows = [make_profile(i + 1) for i in range(args.rows)]
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)
    print(f"Generated {len(rows):,} synthetic roommate profiles -> {output}")


if __name__ == "__main__":
    main()
