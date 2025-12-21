"""
User Schemas

Pydantic schemas for user data validation and serialization.
"""

from typing import Dict, Any, Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field
from uuid import UUID


class UserBase(BaseModel):
    """Base user schema with common fields."""
    email: EmailStr
    name: str = Field(..., min_length=1, max_length=255)


class UserCreate(UserBase):
    """Schema for creating a new user."""
    cognito_user_id: str = Field(..., min_length=1, max_length=255)
    preferences: Optional[Dict[str, Any]] = Field(default_factory=dict)


class UserUpdate(BaseModel):
    """Schema for updating user information."""
    name: Optional[str] = Field(None, min_length=1, max_length=255)
    preferences: Optional[Dict[str, Any]] = None


class UserResponse(UserBase):
    """Schema for user response data."""
    id: UUID
    cognito_user_id: str
    preferences: Dict[str, Any]
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class UserProfile(BaseModel):
    """Schema for user profile information."""
    id: UUID
    email: EmailStr
    name: str
    preferences: Dict[str, Any]
    
    class Config:
        from_attributes = True