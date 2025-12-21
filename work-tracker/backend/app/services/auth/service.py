"""
Authentication Service

Business logic for user authentication, registration, and profile management.
"""

from typing import Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
import structlog

from app.models.user import User
from app.services.auth.cognito_client import cognito_client, CognitoAuthError
from app.services.auth.schemas import (
    LoginRequest, RefreshRequest, TokenResponse, UserRegistrationRequest,
    UserProfile, PasswordResetRequest, PasswordResetConfirmRequest,
    UserPreferencesUpdate
)

logger = structlog.get_logger()


class AuthServiceError(Exception):
    """Custom exception for authentication service errors."""
    
    def __init__(self, message: str, error_code: str = None, status_code: int = 400):
        self.message = message
        self.error_code = error_code
        self.status_code = status_code
        super().__init__(self.message)


class AuthService:
    """Authentication service for user management and authentication."""
    
    async def authenticate_user(self, db: AsyncSession, login_request: LoginRequest) -> TokenResponse:
        """
        Authenticate user with email and password.
        
        Args:
            db: Database session
            login_request: Login credentials
            
        Returns:
            Token response with access and refresh tokens
            
        Raises:
            AuthServiceError: If authentication fails
        """
        try:
            # Authenticate with Cognito
            auth_result = await cognito_client.authenticate_user(
                login_request.email,
                login_request.password
            )
            
            # Get or create user in local database
            user = await self._get_or_create_user(db, auth_result['user_info'])
            
            logger.info(
                "User authenticated successfully",
                user_id=str(user.id),
                email=user.email
            )
            
            return TokenResponse(
                access_token=auth_result['access_token'],
                refresh_token=auth_result['refresh_token'],
                token_type=auth_result['token_type'],
                expires_in=auth_result['expires_in']
            )
            
        except CognitoAuthError as e:
            logger.warning(
                "Authentication failed",
                error_code=e.error_code,
                message=e.message,
                email=login_request.email
            )
            raise AuthServiceError(
                e.message,
                error_code=e.error_code,
                status_code=401
            )
        except Exception as e:
            logger.error(f"Unexpected authentication error: {str(e)}")
            raise AuthServiceError(
                "Authentication service temporarily unavailable",
                error_code="SERVICE_ERROR",
                status_code=500
            )
    
    async def refresh_token(self, refresh_request: RefreshRequest) -> TokenResponse:
        """
        Refresh access token using refresh token.
        
        Args:
            refresh_request: Refresh token request
            
        Returns:
            New token response
            
        Raises:
            AuthServiceError: If token refresh fails
        """
        try:
            auth_result = await cognito_client.refresh_token(refresh_request.refresh_token)
            
            return TokenResponse(
                access_token=auth_result['access_token'],
                refresh_token=refresh_request.refresh_token,  # Refresh token doesn't change
                token_type=auth_result['token_type'],
                expires_in=auth_result['expires_in']
            )
            
        except CognitoAuthError as e:
            logger.warning(
                "Token refresh failed",
                error_code=e.error_code,
                message=e.message
            )
            raise AuthServiceError(
                e.message,
                error_code=e.error_code,
                status_code=401
            )
    
    async def register_user(self, db: AsyncSession, registration_request: UserRegistrationRequest) -> Dict[str, Any]:
        """
        Register a new user.
        
        Args:
            db: Database session
            registration_request: User registration data
            
        Returns:
            Registration result
            
        Raises:
            AuthServiceError: If registration fails
        """
        try:
            # Register with Cognito
            cognito_result = await cognito_client.register_user(
                registration_request.email,
                registration_request.password,
                registration_request.name
            )
            
            # Create user in local database
            user = User(
                email=registration_request.email,
                name=registration_request.name,
                cognito_user_id=cognito_result['user_sub']
            )
            
            db.add(user)
            await db.commit()
            await db.refresh(user)
            
            logger.info(
                "User registered successfully",
                user_id=str(user.id),
                email=user.email,
                confirmation_required=cognito_result['confirmation_required']
            )
            
            return {
                'user_id': str(user.id),
                'email': user.email,
                'name': user.name,
                'confirmation_required': cognito_result['confirmation_required'],
                'delivery_details': cognito_result.get('delivery_details')
            }
            
        except CognitoAuthError as e:
            logger.warning(
                "User registration failed",
                error_code=e.error_code,
                message=e.message,
                email=registration_request.email
            )
            raise AuthServiceError(
                e.message,
                error_code=e.error_code,
                status_code=400
            )
        except IntegrityError:
            await db.rollback()
            raise AuthServiceError(
                "User with this email already exists",
                error_code="USER_EXISTS",
                status_code=409
            )
        except Exception as e:
            await db.rollback()
            logger.error(f"Unexpected registration error: {str(e)}")
            raise AuthServiceError(
                "Registration service temporarily unavailable",
                error_code="SERVICE_ERROR",
                status_code=500
            )
    
    async def get_user_profile(self, db: AsyncSession, user_id: str) -> UserProfile:
        """
        Get user profile by user ID.
        
        Args:
            db: Database session
            user_id: User ID from JWT token
            
        Returns:
            User profile information
            
        Raises:
            AuthServiceError: If user not found
        """
        try:
            # Find user by Cognito user ID
            result = await db.execute(
                select(User).where(User.cognito_user_id == user_id)
            )
            user = result.scalar_one_or_none()
            
            if not user:
                raise AuthServiceError(
                    "User not found",
                    error_code="USER_NOT_FOUND",
                    status_code=404
                )
            
            return UserProfile(
                id=str(user.id),
                email=user.email,
                name=user.name,
                preferences=user.preferences
            )
            
        except AuthServiceError:
            raise
        except Exception as e:
            logger.error(f"Error retrieving user profile: {str(e)}")
            raise AuthServiceError(
                "Failed to retrieve user profile",
                error_code="SERVICE_ERROR",
                status_code=500
            )
    
    async def update_user_preferences(
        self, 
        db: AsyncSession, 
        user_id: str, 
        preferences_update: UserPreferencesUpdate
    ) -> UserProfile:
        """
        Update user preferences.
        
        Args:
            db: Database session
            user_id: User ID from JWT token
            preferences_update: Preferences to update
            
        Returns:
            Updated user profile
            
        Raises:
            AuthServiceError: If user not found or update fails
        """
        try:
            # Find user by Cognito user ID
            result = await db.execute(
                select(User).where(User.cognito_user_id == user_id)
            )
            user = result.scalar_one_or_none()
            
            if not user:
                raise AuthServiceError(
                    "User not found",
                    error_code="USER_NOT_FOUND",
                    status_code=404
                )
            
            # Update preferences
            user.preferences.update(preferences_update.preferences)
            await db.commit()
            await db.refresh(user)
            
            logger.info(
                "User preferences updated",
                user_id=str(user.id),
                preferences_keys=list(preferences_update.preferences.keys())
            )
            
            return UserProfile(
                id=str(user.id),
                email=user.email,
                name=user.name,
                preferences=user.preferences
            )
            
        except AuthServiceError:
            raise
        except Exception as e:
            await db.rollback()
            logger.error(f"Error updating user preferences: {str(e)}")
            raise AuthServiceError(
                "Failed to update user preferences",
                error_code="SERVICE_ERROR",
                status_code=500
            )
    
    async def initiate_password_reset(self, password_reset_request: PasswordResetRequest) -> Dict[str, Any]:
        """
        Initiate password reset process.
        
        Args:
            password_reset_request: Password reset request
            
        Returns:
            Password reset initiation result
            
        Raises:
            AuthServiceError: If password reset initiation fails
        """
        try:
            result = await cognito_client.initiate_password_reset(password_reset_request.email)
            
            logger.info(
                "Password reset initiated",
                email=password_reset_request.email
            )
            
            return {
                'message': 'If an account with this email exists, you will receive password reset instructions.',
                'delivery_details': result.get('delivery_details')
            }
            
        except CognitoAuthError as e:
            logger.warning(
                "Password reset initiation failed",
                error_code=e.error_code,
                message=e.message,
                email=password_reset_request.email
            )
            # For security, always return success message
            return {
                'message': 'If an account with this email exists, you will receive password reset instructions.'
            }
    
    async def confirm_password_reset(self, password_reset_confirm: PasswordResetConfirmRequest) -> Dict[str, Any]:
        """
        Confirm password reset with verification code.
        
        Args:
            password_reset_confirm: Password reset confirmation request
            
        Returns:
            Password reset confirmation result
            
        Raises:
            AuthServiceError: If password reset confirmation fails
        """
        try:
            await cognito_client.confirm_password_reset(
                password_reset_confirm.email,
                password_reset_confirm.confirmation_code,
                password_reset_confirm.new_password
            )
            
            logger.info(
                "Password reset confirmed",
                email=password_reset_confirm.email
            )
            
            return {'message': 'Password reset successful. You can now log in with your new password.'}
            
        except CognitoAuthError as e:
            logger.warning(
                "Password reset confirmation failed",
                error_code=e.error_code,
                message=e.message,
                email=password_reset_confirm.email
            )
            raise AuthServiceError(
                e.message,
                error_code=e.error_code,
                status_code=400
            )
    
    async def _get_or_create_user(self, db: AsyncSession, user_info: Dict[str, Any]) -> User:
        """
        Get existing user or create new user from Cognito user info.
        
        Args:
            db: Database session
            user_info: User information from Cognito
            
        Returns:
            User model instance
        """
        # Try to find existing user by Cognito user ID
        result = await db.execute(
            select(User).where(User.cognito_user_id == user_info['username'])
        )
        user = result.scalar_one_or_none()
        
        if user:
            # Update user info if needed
            if user.email != user_info['email'] or user.name != user_info['name']:
                user.email = user_info['email']
                user.name = user_info['name']
                await db.commit()
                await db.refresh(user)
            return user
        
        # Create new user
        user = User(
            email=user_info['email'],
            name=user_info['name'],
            cognito_user_id=user_info['username']
        )
        
        db.add(user)
        await db.commit()
        await db.refresh(user)
        
        return user


# Global auth service instance
auth_service = AuthService()