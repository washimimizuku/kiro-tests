"""
Authentication Schemas

Pydantic models for authentication requests and responses.
"""

from typing import Optional, Dict, Any
from pydantic import BaseModel, EmailStr, Field


class LoginRequest(BaseModel):
    """Request model for user login."""
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., min_length=8, description="User password")


class RefreshRequest(BaseModel):
    """Request model for token refresh."""
    refresh_token: str = Field(..., description="Refresh token")


class TokenResponse(BaseModel):
    """Response model for authentication tokens."""
    access_token: str = Field(..., description="JWT access token")
    refresh_token: str = Field(..., description="Refresh token")
    token_type: str = Field(default="bearer", description="Token type")
    expires_in: int = Field(..., description="Token expiration time in seconds")


class UserRegistrationRequest(BaseModel):
    """Request model for user registration."""
    email: EmailStr = Field(..., description="User email address")
    password: str = Field(..., min_length=8, description="User password")
    name: str = Field(..., min_length=1, max_length=255, description="User full name")


class UserProfile(BaseModel):
    """User profile information."""
    id: str = Field(..., description="User ID")
    email: str = Field(..., description="User email address")
    name: str = Field(..., description="User full name")
    preferences: Dict[str, Any] = Field(default_factory=dict, description="User preferences")


class PasswordResetRequest(BaseModel):
    """Request model for password reset."""
    email: EmailStr = Field(..., description="User email address")


class PasswordResetConfirmRequest(BaseModel):
    """Request model for password reset confirmation."""
    email: EmailStr = Field(..., description="User email address")
    confirmation_code: str = Field(..., description="Confirmation code from email")
    new_password: str = Field(..., min_length=8, description="New password")


class UserPreferencesUpdate(BaseModel):
    """Request model for updating user preferences."""
    preferences: Dict[str, Any] = Field(..., description="User preferences to update")


class AuthErrorResponse(BaseModel):
    """Error response model for authentication failures."""
    error: str = Field(..., description="Error type")
    message: str = Field(..., description="Human-readable error message")
    details: Optional[Dict[str, Any]] = Field(None, description="Additional error details")