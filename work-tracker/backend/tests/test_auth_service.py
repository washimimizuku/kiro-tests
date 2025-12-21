"""
Unit Tests for Authentication Service

Tests for token generation, validation, and error handling for invalid credentials.
**Validates: Requirements 5.1, 5.2, 5.5**
"""

import pytest
from unittest.mock import Mock, AsyncMock, patch
from datetime import datetime, timedelta
from uuid import uuid4

from app.services.auth.service import AuthService, AuthServiceError
from app.services.auth.schemas import (
    LoginRequest, RefreshRequest, UserRegistrationRequest,
    PasswordResetRequest, PasswordResetConfirmRequest, UserPreferencesUpdate
)
from app.services.auth.cognito_client import CognitoAuthError
from app.models.user import User


class TestAuthService:
    """Unit tests for AuthService class."""
    
    def setup_method(self):
        """Set up test fixtures."""
        self.auth_service = AuthService()
        self.mock_db = AsyncMock()
        
        # Mock user data
        self.test_user = User(
            id=uuid4(),
            email="test@example.com",
            name="Test User",
            cognito_user_id="test-cognito-id",
            preferences={"theme": "dark"}
        )
    
    @pytest.mark.asyncio
    async def test_authenticate_user_success(self):
        """Test successful user authentication."""
        # Arrange
        login_request = LoginRequest(
            email="test@example.com",
            password="testpassword123"
        )
        
        mock_auth_result = {
            'access_token': 'mock-access-token',
            'refresh_token': 'mock-refresh-token',
            'token_type': 'Bearer',
            'expires_in': 3600,
            'user_info': {
                'username': 'test-cognito-id',
                'email': 'test@example.com',
                'name': 'Test User'
            }
        }
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.authenticate_user.return_value = mock_auth_result
            
            # Mock the _get_or_create_user method as an async method
            async def mock_get_or_create_user(db, user_info):
                return self.test_user
            
            with patch.object(self.auth_service, '_get_or_create_user', side_effect=mock_get_or_create_user):
                result = await self.auth_service.authenticate_user(self.mock_db, login_request)
            
            # Verify result
            assert result.access_token == 'mock-access-token'
            assert result.refresh_token == 'mock-refresh-token'
            assert result.token_type == 'Bearer'
            assert result.expires_in == 3600
            
            # Verify Cognito was called correctly
            mock_cognito.authenticate_user.assert_called_once_with(
                "test@example.com", "testpassword123"
            )
    
    @pytest.mark.asyncio
    async def test_authenticate_user_invalid_credentials(self):
        """Test authentication with invalid credentials."""
        # Arrange
        login_request = LoginRequest(
            email="test@example.com",
            password="wrongpassword"
        )
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.authenticate_user.side_effect = CognitoAuthError(
                "Invalid email or password",
                error_code="INVALID_CREDENTIALS"
            )
            
            with pytest.raises(AuthServiceError) as exc_info:
                await self.auth_service.authenticate_user(self.mock_db, login_request)
            
            assert exc_info.value.error_code == "INVALID_CREDENTIALS"
            assert exc_info.value.status_code == 401
            assert "Invalid email or password" in exc_info.value.message
    
    @pytest.mark.asyncio
    async def test_authenticate_user_not_confirmed(self):
        """Test authentication with unconfirmed user account."""
        # Arrange
        login_request = LoginRequest(
            email="unconfirmed@example.com",
            password="testpassword123"
        )
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.authenticate_user.side_effect = CognitoAuthError(
                "User account not confirmed. Please check your email for confirmation instructions.",
                error_code="USER_NOT_CONFIRMED"
            )
            
            with pytest.raises(AuthServiceError) as exc_info:
                await self.auth_service.authenticate_user(self.mock_db, login_request)
            
            assert exc_info.value.error_code == "USER_NOT_CONFIRMED"
            assert "not confirmed" in exc_info.value.message
    
    @pytest.mark.asyncio
    async def test_refresh_token_success(self):
        """Test successful token refresh."""
        # Arrange
        refresh_request = RefreshRequest(refresh_token="valid-refresh-token")
        
        mock_refresh_result = {
            'access_token': 'new-access-token',
            'token_type': 'Bearer',
            'expires_in': 3600
        }
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.refresh_token.return_value = mock_refresh_result
            
            result = await self.auth_service.refresh_token(refresh_request)
            
            assert result.access_token == 'new-access-token'
            assert result.refresh_token == 'valid-refresh-token'  # Should remain same
            assert result.token_type == 'Bearer'
            assert result.expires_in == 3600
    
    @pytest.mark.asyncio
    async def test_refresh_token_invalid(self):
        """Test token refresh with invalid refresh token."""
        # Arrange
        refresh_request = RefreshRequest(refresh_token="invalid-refresh-token")
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.refresh_token.side_effect = CognitoAuthError(
                "Invalid or expired refresh token",
                error_code="INVALID_REFRESH_TOKEN"
            )
            
            with pytest.raises(AuthServiceError) as exc_info:
                await self.auth_service.refresh_token(refresh_request)
            
            assert exc_info.value.error_code == "INVALID_REFRESH_TOKEN"
            assert exc_info.value.status_code == 401
    
    @pytest.mark.asyncio
    async def test_register_user_success(self):
        """Test successful user registration."""
        # Arrange
        registration_request = UserRegistrationRequest(
            email="newuser@example.com",
            password="newpassword123",
            name="New User"
        )
        
        mock_cognito_result = {
            'user_sub': 'new-cognito-id',
            'confirmation_required': True,
            'delivery_details': {'destination': 'n***@example.com'}
        }
        
        # Mock database operations
        self.mock_db.add = Mock()
        self.mock_db.commit = AsyncMock()
        self.mock_db.refresh = AsyncMock()
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.register_user.return_value = mock_cognito_result
            
            result = await self.auth_service.register_user(self.mock_db, registration_request)
            
            # Verify result structure
            assert 'user_id' in result
            assert result['email'] == 'newuser@example.com'
            assert result['name'] == 'New User'
            assert result['confirmation_required'] is True
            
            # Verify database operations
            self.mock_db.add.assert_called_once()
            self.mock_db.commit.assert_called_once()
            self.mock_db.refresh.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_register_user_already_exists(self):
        """Test registration with existing email."""
        # Arrange
        registration_request = UserRegistrationRequest(
            email="existing@example.com",
            password="password123",
            name="Existing User"
        )
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.register_user.side_effect = CognitoAuthError(
                "An account with this email already exists",
                error_code="USER_EXISTS"
            )
            
            with pytest.raises(AuthServiceError) as exc_info:
                await self.auth_service.register_user(self.mock_db, registration_request)
            
            assert exc_info.value.error_code == "USER_EXISTS"
            assert exc_info.value.status_code == 400
    
    @pytest.mark.asyncio
    async def test_get_user_profile_success(self):
        """Test successful user profile retrieval."""
        # Arrange
        user_id = "test-cognito-id"
        
        # Mock database query
        mock_result = Mock()
        mock_result.scalar_one_or_none.return_value = self.test_user
        self.mock_db.execute.return_value = mock_result
        
        # Act
        result = await self.auth_service.get_user_profile(self.mock_db, user_id)
        
        # Assert
        assert result.id == str(self.test_user.id)
        assert result.email == self.test_user.email
        assert result.name == self.test_user.name
        assert result.preferences == self.test_user.preferences
    
    @pytest.mark.asyncio
    async def test_get_user_profile_not_found(self):
        """Test user profile retrieval for non-existent user."""
        # Arrange
        user_id = "non-existent-id"
        
        # Mock database query returning None
        mock_result = Mock()
        mock_result.scalar_one_or_none.return_value = None
        self.mock_db.execute.return_value = mock_result
        
        # Act & Assert
        with pytest.raises(AuthServiceError) as exc_info:
            await self.auth_service.get_user_profile(self.mock_db, user_id)
        
        assert exc_info.value.error_code == "USER_NOT_FOUND"
        assert exc_info.value.status_code == 404
    
    @pytest.mark.asyncio
    async def test_update_user_preferences_success(self):
        """Test successful user preferences update."""
        # Arrange
        user_id = "test-cognito-id"
        preferences_update = UserPreferencesUpdate(
            preferences={"theme": "light", "notifications": True}
        )
        
        # Mock database operations
        mock_result = Mock()
        mock_result.scalar_one_or_none.return_value = self.test_user
        self.mock_db.execute.return_value = mock_result
        self.mock_db.commit = AsyncMock()
        self.mock_db.refresh = AsyncMock()
        
        # Act
        result = await self.auth_service.update_user_preferences(
            self.mock_db, user_id, preferences_update
        )
        
        # Assert
        assert result.preferences["theme"] == "light"
        assert result.preferences["notifications"] is True
        self.mock_db.commit.assert_called_once()
        self.mock_db.refresh.assert_called_once()
    
    @pytest.mark.asyncio
    async def test_initiate_password_reset_success(self):
        """Test successful password reset initiation."""
        # Arrange
        password_reset_request = PasswordResetRequest(email="test@example.com")
        
        mock_result = {
            'delivery_details': {'destination': 't***@example.com'}
        }
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.initiate_password_reset.return_value = mock_result
            
            result = await self.auth_service.initiate_password_reset(password_reset_request)
            
            assert 'message' in result
            assert 'delivery_details' in result
            mock_cognito.initiate_password_reset.assert_called_once_with("test@example.com")
    
    @pytest.mark.asyncio
    async def test_initiate_password_reset_user_not_found(self):
        """Test password reset initiation for non-existent user."""
        # Arrange
        password_reset_request = PasswordResetRequest(email="nonexistent@example.com")
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.initiate_password_reset.side_effect = CognitoAuthError(
                "User not found",
                error_code="USER_NOT_FOUND"
            )
            
            # Should still return success message for security
            result = await self.auth_service.initiate_password_reset(password_reset_request)
            
            assert 'message' in result
            assert 'If an account with this email exists' in result['message']
    
    @pytest.mark.asyncio
    async def test_confirm_password_reset_success(self):
        """Test successful password reset confirmation."""
        # Arrange
        confirm_request = PasswordResetConfirmRequest(
            email="test@example.com",
            confirmation_code="123456",
            new_password="newpassword123"
        )
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.confirm_password_reset.return_value = True
            
            result = await self.auth_service.confirm_password_reset(confirm_request)
            
            assert 'message' in result
            assert 'successful' in result['message']
            mock_cognito.confirm_password_reset.assert_called_once_with(
                "test@example.com", "123456", "newpassword123"
            )
    
    @pytest.mark.asyncio
    async def test_confirm_password_reset_invalid_code(self):
        """Test password reset confirmation with invalid code."""
        # Arrange
        confirm_request = PasswordResetConfirmRequest(
            email="test@example.com",
            confirmation_code="invalid",
            new_password="newpassword123"
        )
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.confirm_password_reset.side_effect = CognitoAuthError(
                "Invalid verification code",
                error_code="INVALID_CODE"
            )
            
            with pytest.raises(AuthServiceError) as exc_info:
                await self.auth_service.confirm_password_reset(confirm_request)
            
            assert exc_info.value.error_code == "INVALID_CODE"
            assert exc_info.value.status_code == 400
    
    @pytest.mark.asyncio
    async def test_confirm_password_reset_expired_code(self):
        """Test password reset confirmation with expired code."""
        # Arrange
        confirm_request = PasswordResetConfirmRequest(
            email="test@example.com",
            confirmation_code="expired",
            new_password="newpassword123"
        )
        
        # Act & Assert
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.confirm_password_reset.side_effect = CognitoAuthError(
                "Verification code has expired",
                error_code="EXPIRED_CODE"
            )
            
            with pytest.raises(AuthServiceError) as exc_info:
                await self.auth_service.confirm_password_reset(confirm_request)
            
            assert exc_info.value.error_code == "EXPIRED_CODE"
            assert exc_info.value.status_code == 400
    
    @pytest.mark.asyncio
    async def test_get_or_create_user_existing(self):
        """Test _get_or_create_user with existing user."""
        # Arrange
        user_info = {
            'username': 'test-cognito-id',
            'email': 'test@example.com',
            'name': 'Test User'
        }
        
        # Mock database query
        mock_result = Mock()
        mock_result.scalar_one_or_none.return_value = self.test_user
        self.mock_db.execute.return_value = mock_result
        self.mock_db.commit = AsyncMock()
        self.mock_db.refresh = AsyncMock()
        
        # Act
        result = await self.auth_service._get_or_create_user(self.mock_db, user_info)
        
        # Assert
        assert result == self.test_user
        # Should not create new user
        self.mock_db.add.assert_not_called() if hasattr(self.mock_db, 'add') else None
    
    @pytest.mark.asyncio
    async def test_get_or_create_user_new(self):
        """Test _get_or_create_user with new user."""
        # Arrange
        user_info = {
            'username': 'new-cognito-id',
            'email': 'newuser@example.com',
            'name': 'New User'
        }
        
        # Mock database query returning None (user doesn't exist)
        mock_result = Mock()
        mock_result.scalar_one_or_none.return_value = None
        self.mock_db.execute.return_value = mock_result
        self.mock_db.add = Mock()
        self.mock_db.commit = AsyncMock()
        self.mock_db.refresh = AsyncMock()
        
        # Act
        result = await self.auth_service._get_or_create_user(self.mock_db, user_info)
        
        # Assert
        self.mock_db.add.assert_called_once()
        self.mock_db.commit.assert_called_once()
        self.mock_db.refresh.assert_called_once()
        
        # Verify the created user has correct attributes
        created_user = self.mock_db.add.call_args[0][0]
        assert created_user.email == 'newuser@example.com'
        assert created_user.name == 'New User'
        assert created_user.cognito_user_id == 'new-cognito-id'