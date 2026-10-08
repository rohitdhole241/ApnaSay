import pytest
from pydantic import ValidationError

from app.schemas.user import UserCreate


def test_user_create_accepts_valid_details():
    user = UserCreate(
        name='Aman Sharma',
        email='aman@example.com',
        phone='9876543210',
        password='StrongPass123!',
        role='user',
    )

    assert user.email == 'aman@example.com'
    assert user.phone == '9876543210'
    assert user.password == 'StrongPass123!'


def test_user_create_rejects_invalid_email():
    with pytest.raises(ValidationError):
        UserCreate(
            name='Aman',
            email='amanexample.com',
            phone='9876543210',
            password='StrongPass123!',
        )


def test_user_create_rejects_invalid_phone_number():
    with pytest.raises(ValidationError):
        UserCreate(
            name='Aman',
            email='aman@example.com',
            phone='12345',
            password='StrongPass123!',
        )


def test_user_create_rejects_weak_password():
    with pytest.raises(ValidationError):
        UserCreate(
            name='Aman',
            email='aman@example.com',
            phone='9876543210',
            password='123',
        )
