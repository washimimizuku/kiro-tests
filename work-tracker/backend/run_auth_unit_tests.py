#!/usr/bin/env python3
"""
Simple unit test runner for authentication service tests.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

import asyncio
from unittest.mock import Mock, AsyncMock, patch
from uuid import uuid4

from app.services.auth.service import AuthService, AuthServiceError
from app.services.auth.schemas import (
    LoginRequest, RefreshRequest, UserRegistrationRequest,
    PasswordResetRequest, PasswordResetConfirmRequest, UserPreferencesUpdate
)
from app.services.auth.cognito_client import CognitoAuthError
from app.models.user import User


class SimpleAuthServiceTests:
    """Simple unit tests for AuthService."""
    
    def __init__(self):
        self.auth_service = AuthService()
        self.test_user = User(
            id=uuid4(),
            email="test@example.com",
            name="Test User",
            cognito_user_id="test-cognito-id",
            preferences={"theme": "dark"}
        )
    
    async def test_authenticate_user_success(self):
        """Test successful user authentication."""
        mock_db = AsyncMock()
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
        
        # Mock database operations
        mock_db.execute.return_value.scalar_one_or_none.return_value = self.test_user
        
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.authenticate_user.return_value = mock_auth_result
            
            result = await self.auth_service.authenticate_user(mock_db, login_request)
            
            assert result.access_token == 'mock-access-token'
            assert result.refresh_token == 'mock-refresh-token'
            assert result.token_type == 'Bearer'
            assert result.expires_in == 3600
            
            print("✅ test_authenticate_user_success passed")
    
    async def test_authenticate_user_invalid_credentials(self):
        """Test authentication with invalid credentials."""
        mock_db = AsyncMock()
        login_request = LoginRequest(
            email="test@example.com",
            password="wrongpassword"
        )
        
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.authenticate_user.side_effect = CognitoAuthError(
                "Invalid email or password",
                error_code="INVALID_CREDENTIALS"
            )
            
            try:
                await self.auth_service.authenticate_user(mock_db, login_request)
                assert False, "Should have raised AuthServiceError"
            except AuthServiceError as e:
                assert e.error_code == "INVALID_CREDENTIALS"
                assert e.status_code == 401
                print("✅ test_authenticate_user_invalid_credentials passed")
    
    async def test_refresh_token_success(self):
        """Test successful token refresh."""
        refresh_request = RefreshRequest(refresh_token="valid-refresh-token")
        
        mock_refresh_result = {
            'access_token': 'new-access-token',
            'token_type': 'Bearer',
            'expires_in': 3600
        }
        
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.refresh_token.return_value = mock_refresh_result
            
            result = await self.auth_service.refresh_token(refresh_request)
            
            assert result.access_token == 'new-access-token'
            assert result.refresh_token == 'valid-refresh-token'
            assert result.token_type == 'Bearer'
            assert result.expires_in == 3600
            
            print("✅ test_refresh_token_success passed")
    
    async def test_refresh_token_invalid(self):
        """Test token refresh with invalid refresh token."""
        refresh_request = RefreshRequest(refresh_token="invalid-refresh-token")
        
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.refresh_token.side_effect = CognitoAuthError(
                "Invalid or expired refresh token",
                error_code="INVALID_REFRESH_TOKEN"
            )
            
            try:
                await self.auth_service.refresh_token(refresh_request)
                assert False, "Should have raised AuthServiceError"
            except AuthServiceError as e:
                assert e.error_code == "INVALID_REFRESH_TOKEN"
                assert e.status_code == 401
                print("✅ test_refresh_token_invalid passed")
    
    async def test_get_user_profile_success(self):
        """Test successful user profile retrieval."""
        mock_db = AsyncMock()
        user_id = "test-cognito-id"
        
        # Mock database query
        mock_db.execute.return_value.scalar_one_or_none.return_value = self.test_user
        
        result = await self.auth_service.get_user_profile(mock_db, user_id)
        
        assert result.id == str(self.test_user.id)
        assert result.email == self.test_user.email
        assert result.name == self.test_user.name
        assert result.preferences == self.test_user.preferences
        
        print("✅ test_get_user_profile_success passed")
    
    async def test_get_user_profile_not_found(self):
        """Test user profile retrieval for non-existent user."""
        mock_db = AsyncMock()
        user_id = "non-existent-id"
        
        # Mock database query returning None
        mock_db.execute.return_value.scalar_one_or_none.return_value = None
        
        try:
            await self.auth_service.get_user_profile(mock_db, user_id)
            assert False, "Should have raised AuthServiceError"
        except AuthServiceError as e:
            assert e.error_code == "USER_NOT_FOUND"
            assert e.status_code == 404
            print("✅ test_get_user_profile_not_found passed")
    
    async def test_initiate_password_reset_success(self):
        """Test successful password reset initiation."""
        password_reset_request = PasswordResetRequest(email="test@example.com")
        
        mock_result = {
            'delivery_details': {'destination': 't***@example.com'}
        }
        
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.initiate_password_reset.return_value = mock_result
            
            result = await self.auth_service.initiate_password_reset(password_reset_request)
            
            assert 'message' in result
            assert 'delivery_details' in result
            print("✅ test_initiate_password_reset_success passed")
    
    async def test_confirm_password_reset_success(self):
        """Test successful password reset confirmation."""
        confirm_request = PasswordResetConfirmRequest(
            email="test@example.com",
            confirmation_code="123456",
            new_password="newpassword123"
        )
        
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.confirm_password_reset.return_value = True
            
            result = await self.auth_service.confirm_password_reset(confirm_request)
            
            assert 'message' in result
            assert 'successful' in result['message']
            print("✅ test_confirm_password_reset_success passed")
    
    async def test_confirm_password_reset_invalid_code(self):
        """Test password reset confirmation with invalid code."""
        confirm_request = PasswordResetConfirmRequest(
            email="test@example.com",
            confirmation_code="invalid",
            new_password="newpassword123"
        )
        
        with patch('app.services.auth.service.cognito_client') as mock_cognito:
            mock_cognito.confirm_password_reset.side_effect = CognitoAuthError(
                "Invalid verification code",
                error_code="INVALID_CODE"
            )
            
            try:
                await self.auth_service.confirm_password_reset(confirm_request)
                assert False, "Should have raised AuthServiceError"
            except AuthServiceError as e:
                assert e.error_code == "INVALID_CODE"
                assert e.status_code == 400
                print("✅ test_confirm_password_reset_invalid_code passed")


async def run_tests():
    """Run all authentication service unit tests."""
    print("Running Authentication Service Unit Tests...")
    print("**Validates: Requirements 5.1, 5.2, 5.5**")
    
    tests = SimpleAuthServiceTests()
    
    test_methods = [
        tests.test_authenticate_user_success,
        tests.test_authenticate_user_invalid_credentials,
        tests.test_refresh_token_success,
        tests.test_refresh_token_invalid,
        tests.test_get_user_profile_success,
        tests.test_get_user_profile_not_found,
        tests.test_initiate_password_reset_success,
        tests.test_confirm_password_reset_success,
        tests.test_confirm_password_reset_invalid_code,
    ]
    
    passed = 0
    failed = 0
    
    for test_method in test_methods:
        try:
            await test_method()
            passed += 1
        except Exception as e:
            print(f"❌ {test_method.__name__} failed: {e}")
            failed += 1
    
    print(f"\n📊 Test Results: {passed} passed, {failed} failed")
    
    if failed > 0:
        print("❌ Some tests failed")
        return False
    else:
        print("🎉 All authentication service unit tests passed!")
        return True


if __name__ == "__main__":
    success = asyncio.run(run_tests())
    if not success:
        sys.exit(1)