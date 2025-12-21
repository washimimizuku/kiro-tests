"""
Authentication Router

FastAPI router for authentication endpoints including login, logout, registration,
and user management.
"""

from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
import structlog

from app.core.database import get_db
from app.services.auth.schemas import (
    LoginRequest, RefreshRequest, TokenResponse, UserRegistrationRequest,
    UserProfile, PasswordResetRequest, PasswordResetConfirmRequest,
    UserPreferencesUpdate, AuthErrorResponse
)
from app.services.auth.service import auth_service, AuthServiceError
from app.services.auth.jwt_middleware import get_current_user

logger = structlog.get_logger()

# Create authentication router
router = APIRouter()


@router.post(
    "/login",
    response_model=TokenResponse,
    responses={
        401: {"model": AuthErrorResponse, "description": "Authentication failed"},
        500: {"model": AuthErrorResponse, "description": "Service error"}
    },
    summary="User Login",
    description="Authenticate user with email and password, returning JWT tokens"
)
async def login(
    login_request: LoginRequest,
    db: AsyncSession = Depends(get_db)
) -> TokenResponse:
    """
    Authenticate user and return JWT tokens.
    
    - **email**: User email address
    - **password**: User password
    
    Returns access token and refresh token for authenticated sessions.
    """
    try:
        return await auth_service.authenticate_user(db, login_request)
    except AuthServiceError as e:
        logger.warning(
            "Login failed",
            error_code=e.error_code,
            message=e.message,
            email=login_request.email
        )
        raise HTTPException(
            status_code=e.status_code,
            detail={
                "error": e.error_code or "AUTHENTICATION_FAILED",
                "message": e.message
            }
        )


@router.post(
    "/refresh",
    response_model=TokenResponse,
    responses={
        401: {"model": AuthErrorResponse, "description": "Invalid refresh token"},
        500: {"model": AuthErrorResponse, "description": "Service error"}
    },
    summary="Refresh Token",
    description="Refresh access token using valid refresh token"
)
async def refresh_token(refresh_request: RefreshRequest) -> TokenResponse:
    """
    Refresh access token using refresh token.
    
    - **refresh_token**: Valid refresh token
    
    Returns new access token with extended expiration.
    """
    try:
        return await auth_service.refresh_token(refresh_request)
    except AuthServiceError as e:
        logger.warning(
            "Token refresh failed",
            error_code=e.error_code,
            message=e.message
        )
        raise HTTPException(
            status_code=e.status_code,
            detail={
                "error": e.error_code or "TOKEN_REFRESH_FAILED",
                "message": e.message
            }
        )


@router.post(
    "/register",
    response_model=Dict[str, Any],
    responses={
        400: {"model": AuthErrorResponse, "description": "Registration failed"},
        409: {"model": AuthErrorResponse, "description": "User already exists"},
        500: {"model": AuthErrorResponse, "description": "Service error"}
    },
    summary="User Registration",
    description="Register new user account with email verification"
)
async def register(
    registration_request: UserRegistrationRequest,
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Register a new user account.
    
    - **email**: User email address (must be unique)
    - **password**: User password (minimum 8 characters)
    - **name**: User full name
    
    Returns registration result with confirmation requirements.
    """
    try:
        return await auth_service.register_user(db, registration_request)
    except AuthServiceError as e:
        logger.warning(
            "Registration failed",
            error_code=e.error_code,
            message=e.message,
            email=registration_request.email
        )
        raise HTTPException(
            status_code=e.status_code,
            detail={
                "error": e.error_code or "REGISTRATION_FAILED",
                "message": e.message
            }
        )


@router.get(
    "/profile",
    response_model=UserProfile,
    responses={
        401: {"model": AuthErrorResponse, "description": "Authentication required"},
        404: {"model": AuthErrorResponse, "description": "User not found"},
        500: {"model": AuthErrorResponse, "description": "Service error"}
    },
    summary="Get User Profile",
    description="Get current user profile information"
)
async def get_profile(
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> UserProfile:
    """
    Get current user profile information.
    
    Requires valid JWT token in Authorization header.
    Returns user profile with preferences.
    """
    try:
        return await auth_service.get_user_profile(db, current_user['user_id'])
    except AuthServiceError as e:
        logger.warning(
            "Get profile failed",
            error_code=e.error_code,
            message=e.message,
            user_id=current_user.get('user_id')
        )
        raise HTTPException(
            status_code=e.status_code,
            detail={
                "error": e.error_code or "PROFILE_RETRIEVAL_FAILED",
                "message": e.message
            }
        )


@router.put(
    "/profile/preferences",
    response_model=UserProfile,
    responses={
        401: {"model": AuthErrorResponse, "description": "Authentication required"},
        404: {"model": AuthErrorResponse, "description": "User not found"},
        500: {"model": AuthErrorResponse, "description": "Service error"}
    },
    summary="Update User Preferences",
    description="Update user preferences and settings"
)
async def update_preferences(
    preferences_update: UserPreferencesUpdate,
    current_user: Dict[str, Any] = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> UserProfile:
    """
    Update user preferences.
    
    - **preferences**: Dictionary of preference key-value pairs
    
    Requires valid JWT token in Authorization header.
    Returns updated user profile.
    """
    try:
        return await auth_service.update_user_preferences(
            db, current_user['user_id'], preferences_update
        )
    except AuthServiceError as e:
        logger.warning(
            "Update preferences failed",
            error_code=e.error_code,
            message=e.message,
            user_id=current_user.get('user_id')
        )
        raise HTTPException(
            status_code=e.status_code,
            detail={
                "error": e.error_code or "PREFERENCES_UPDATE_FAILED",
                "message": e.message
            }
        )


@router.post(
    "/password-reset",
    response_model=Dict[str, Any],
    responses={
        500: {"model": AuthErrorResponse, "description": "Service error"}
    },
    summary="Initiate Password Reset",
    description="Send password reset instructions to user email"
)
async def initiate_password_reset(
    password_reset_request: PasswordResetRequest
) -> Dict[str, Any]:
    """
    Initiate password reset process.
    
    - **email**: User email address
    
    Sends password reset instructions to email if account exists.
    Always returns success message for security.
    """
    try:
        return await auth_service.initiate_password_reset(password_reset_request)
    except Exception as e:
        logger.error(f"Password reset initiation error: {str(e)}")
        # Always return success message for security
        return {
            'message': 'If an account with this email exists, you will receive password reset instructions.'
        }


@router.post(
    "/password-reset/confirm",
    response_model=Dict[str, Any],
    responses={
        400: {"model": AuthErrorResponse, "description": "Invalid confirmation code or password"},
        500: {"model": AuthErrorResponse, "description": "Service error"}
    },
    summary="Confirm Password Reset",
    description="Confirm password reset with verification code"
)
async def confirm_password_reset(
    password_reset_confirm: PasswordResetConfirmRequest
) -> Dict[str, Any]:
    """
    Confirm password reset with verification code.
    
    - **email**: User email address
    - **confirmation_code**: Verification code from email
    - **new_password**: New password (minimum 8 characters)
    
    Completes password reset process if code is valid.
    """
    try:
        return await auth_service.confirm_password_reset(password_reset_confirm)
    except AuthServiceError as e:
        logger.warning(
            "Password reset confirmation failed",
            error_code=e.error_code,
            message=e.message,
            email=password_reset_confirm.email
        )
        raise HTTPException(
            status_code=e.status_code,
            detail={
                "error": e.error_code or "PASSWORD_RESET_FAILED",
                "message": e.message
            }
        )


@router.post(
    "/logout",
    response_model=Dict[str, str],
    summary="User Logout",
    description="Logout user (client-side token invalidation)"
)
async def logout() -> Dict[str, str]:
    """
    Logout user.
    
    Note: JWT tokens are stateless, so logout is handled client-side
    by removing tokens from storage. This endpoint provides a consistent
    API interface and can be extended for server-side token blacklisting.
    """
    logger.info("User logout endpoint called")
    return {"message": "Logout successful. Please remove tokens from client storage."}


@router.get(
    "/health",
    response_model=Dict[str, str],
    summary="Authentication Service Health",
    description="Health check for authentication service"
)
async def auth_health() -> Dict[str, str]:
    """Authentication service health check."""
    return {
        "status": "healthy",
        "service": "authentication",
        "version": "1.0.0"
    }