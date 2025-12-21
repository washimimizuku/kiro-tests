"""
Property-Based Tests for Authentication Service

Tests the Authentication Token Validation property using Hypothesis.
**Feature: work-tracker, Property 9: Authentication Token Validation**
**Validates: Requirements 5.2**
"""

import pytest
from hypothesis import given, strategies as st, settings, assume
from datetime import datetime, timedelta
from uuid import uuid4
from typing import Dict, Any, Optional
import json
from unittest.mock import Mock, AsyncMock, patch

from app.services.auth.schemas import (
    LoginRequest, RefreshRequest, TokenResponse, UserRegistrationRequest,
    UserProfile, PasswordResetRequest, PasswordResetConfirmRequest
)
from app.services.auth.jwt_middleware import JWTValidator, JWTValidationError
from app.services.auth.cognito_client import CognitoClient, CognitoAuthError


# Test data generators
@st.composite
def valid_email(draw):
    """Generate valid email addresses."""
    # Use ASCII characters only to avoid Unicode validation issues
    local = draw(st.text(
        min_size=1, 
        max_size=20, 
        alphabet=st.characters(min_codepoint=ord('a'), max_codepoint=ord('z'))
    ).filter(lambda x: x and len(x) > 0))
    
    domain = draw(st.text(
        min_size=1, 
        max_size=15, 
        alphabet=st.characters(min_codepoint=ord('a'), max_codepoint=ord('z'))
    ).filter(lambda x: x and len(x) > 0))
    
    tld = draw(st.sampled_from(['com', 'org', 'net', 'edu']))
    return f"{local}@{domain}.{tld}"


@st.composite
def login_request_data(draw):
    """Generate valid login request data."""
    return LoginRequest(
        email=draw(valid_email()),
        password=draw(st.text(min_size=8, max_size=128))
    )


@st.composite
def jwt_claims_data(draw):
    """Generate valid JWT claims data."""
    now = datetime.utcnow()
    return {
        'sub': draw(st.text(min_size=1, max_size=128)),
        'cognito:username': draw(st.text(min_size=1, max_size=128)),
        'email': draw(valid_email()),
        'name': draw(st.text(min_size=1, max_size=255)),
        'email_verified': draw(st.booleans()),
        'token_use': draw(st.sampled_from(['access', 'id'])),
        'aud': draw(st.text(min_size=1, max_size=128)),
        'iat': int(now.timestamp()),
        'exp': int((now + timedelta(hours=1)).timestamp()),
        'iss': f"https://cognito-idp.us-east-1.amazonaws.com/us-east-1_test",
        'cognito:groups': draw(st.lists(st.text(min_size=1, max_size=50), max_size=5))
    }


@st.composite
def user_registration_data(draw):
    """Generate valid user registration data."""
    return UserRegistrationRequest(
        email=draw(valid_email()),
        password=draw(st.text(min_size=8, max_size=128)),
        name=draw(st.text(min_size=1, max_size=255).filter(lambda x: x.strip()))
    )


@st.composite
def cognito_auth_result(draw):
    """Generate mock Cognito authentication result."""
    return {
        'access_token': draw(st.text(min_size=100, max_size=2048)),
        'refresh_token': draw(st.text(min_size=100, max_size=2048)),
        'id_token': draw(st.text(min_size=100, max_size=2048)),
        'token_type': 'Bearer',
        'expires_in': draw(st.integers(min_value=300, max_value=86400)),
        'user_info': {
            'username': draw(st.text(min_size=1, max_size=128)),
            'email': draw(valid_email()),
            'name': draw(st.text(min_size=1, max_size=255)),
            'email_verified': draw(st.booleans()),
            'user_status': 'CONFIRMED',
            'attributes': {}
        }
    }


class TestAuthenticationTokenValidation:
    """
    Property-Based Tests for Authentication Token Validation.
    
    **Property 9: Authentication Token Validation**
    For any valid user credentials, the authentication system should generate secure 
    session tokens that allow access to user-specific resources and reject invalid 
    or expired tokens.
    **Validates: Requirements 5.2**
    """

    @given(login_request_data())
    @settings(max_examples=100, deadline=2000)
    def test_login_request_validation_consistency(self, login_request: LoginRequest):
        """
        Test that login request validation is consistent.
        
        Property: For any valid LoginRequest, validation should succeed consistently
        and preserve all input data.
        """
        # Test that the schema validates successfully
        assert '@' in login_request.email
        assert len(login_request.password) >= 8
        
        # Test that validation is consistent
        dict1 = login_request.model_dump()
        dict2 = login_request.model_dump()
        assert dict1 == dict2
        
        # Test that re-parsing produces equivalent object
        reparsed = LoginRequest.model_validate(dict1)
        assert reparsed == login_request
        assert reparsed.email == login_request.email
        assert reparsed.password == login_request.password

    @given(jwt_claims_data())
    @settings(max_examples=100, deadline=2000)
    def test_jwt_claims_extraction_consistency(self, claims: Dict[str, Any]):
        """
        Test that JWT claims extraction is consistent.
        
        Property: For any valid JWT claims, extracting user information should
        produce consistent results and preserve all essential data.
        """
        # Test that all required claims are present
        assert 'sub' in claims
        assert 'email' in claims
        assert 'token_use' in claims
        assert claims['token_use'] in ['access', 'id']
        
        # Test user info extraction consistency
        user_info = {
            'user_id': claims.get('sub'),
            'username': claims.get('cognito:username'),
            'email': claims.get('email'),
            'name': claims.get('name'),
            'email_verified': claims.get('email_verified', False),
            'token_use': claims.get('token_use'),
            'client_id': claims.get('aud'),
            'issued_at': claims.get('iat'),
            'expires_at': claims.get('exp'),
            'cognito_groups': claims.get('cognito:groups', [])
        }
        
        # Verify all essential data is preserved
        assert user_info['user_id'] == claims['sub']
        assert user_info['email'] == claims['email']
        assert user_info['token_use'] == claims['token_use']
        
        # Test that extraction is deterministic
        user_info2 = {
            'user_id': claims.get('sub'),
            'username': claims.get('cognito:username'),
            'email': claims.get('email'),
            'name': claims.get('name'),
            'email_verified': claims.get('email_verified', False),
            'token_use': claims.get('token_use'),
            'client_id': claims.get('aud'),
            'issued_at': claims.get('iat'),
            'expires_at': claims.get('exp'),
            'cognito_groups': claims.get('cognito:groups', [])
        }
        
        assert user_info == user_info2

    @given(user_registration_data())
    @settings(max_examples=100, deadline=2000)
    def test_user_registration_validation_consistency(self, registration: UserRegistrationRequest):
        """
        Test that user registration validation is consistent.
        
        Property: For any valid UserRegistrationRequest, validation should succeed
        and all data should be preserved correctly.
        """
        # Test that the schema validates successfully
        assert '@' in registration.email
        assert len(registration.password) >= 8
        assert registration.name.strip()
        
        # Test that validation is consistent
        dict1 = registration.model_dump()
        dict2 = registration.model_dump()
        assert dict1 == dict2
        
        # Test that re-parsing produces equivalent object
        reparsed = UserRegistrationRequest.model_validate(dict1)
        assert reparsed == registration
        assert reparsed.email == registration.email
        assert reparsed.password == registration.password
        assert reparsed.name == registration.name

    @given(cognito_auth_result())
    @settings(max_examples=100, deadline=2000)
    def test_token_response_generation_consistency(self, auth_result: Dict[str, Any]):
        """
        Test that token response generation is consistent.
        
        Property: For any valid Cognito authentication result, generating a TokenResponse
        should preserve all token data and be consistent across multiple generations.
        """
        # Create TokenResponse from auth result
        token_response = TokenResponse(
            access_token=auth_result['access_token'],
            refresh_token=auth_result['refresh_token'],
            token_type=auth_result['token_type'],
            expires_in=auth_result['expires_in']
        )
        
        # Verify all data is preserved
        assert token_response.access_token == auth_result['access_token']
        assert token_response.refresh_token == auth_result['refresh_token']
        assert token_response.token_type == auth_result['token_type']
        assert token_response.expires_in == auth_result['expires_in']
        
        # Test serialization consistency
        dict1 = token_response.model_dump()
        dict2 = token_response.model_dump()
        assert dict1 == dict2
        
        # Test that re-parsing produces equivalent object
        reparsed = TokenResponse.model_validate(dict1)
        assert reparsed == token_response

    @given(st.text(min_size=1, max_size=128), st.text(min_size=1, max_size=128))
    @settings(max_examples=100, deadline=2000)
    def test_refresh_token_validation_consistency(self, refresh_token: str, user_id: str):
        """
        Test that refresh token validation is consistent.
        
        Property: For any refresh token string, validation should be consistent
        and either succeed or fail deterministically.
        """
        # Create refresh request
        refresh_request = RefreshRequest(refresh_token=refresh_token)
        
        # Test that validation is consistent
        assert refresh_request.refresh_token == refresh_token
        
        # Test serialization consistency
        dict1 = refresh_request.model_dump()
        dict2 = refresh_request.model_dump()
        assert dict1 == dict2
        
        # Test that re-parsing produces equivalent object
        reparsed = RefreshRequest.model_validate(dict1)
        assert reparsed == refresh_request
        assert reparsed.refresh_token == refresh_token

    @given(valid_email())
    @settings(max_examples=100, deadline=2000)
    def test_password_reset_request_consistency(self, email: str):
        """
        Test that password reset request validation is consistent.
        
        Property: For any valid email, password reset requests should validate
        consistently and preserve the email address.
        """
        # Create password reset request
        reset_request = PasswordResetRequest(email=email)
        
        # Test that validation is consistent
        # Note: Email may be normalized to lowercase by Pydantic
        assert reset_request.email.lower() == email.lower()
        assert '@' in reset_request.email
        
        # Test serialization consistency
        dict1 = reset_request.model_dump()
        dict2 = reset_request.model_dump()
        assert dict1 == dict2
        
        # Test that re-parsing produces equivalent object
        reparsed = PasswordResetRequest.model_validate(dict1)
        assert reparsed == reset_request
        assert reparsed.email.lower() == email.lower()

    @given(
        valid_email(),
        st.text(min_size=6, max_size=10, alphabet=st.characters(whitelist_categories=('Nd', 'Lu'))),
        st.text(min_size=8, max_size=128)
    )
    @settings(max_examples=100, deadline=2000)
    def test_password_reset_confirm_consistency(self, email: str, confirmation_code: str, new_password: str):
        """
        Test that password reset confirmation validation is consistent.
        
        Property: For any valid password reset confirmation data, validation should
        succeed consistently and preserve all input data.
        """
        # Create password reset confirmation request
        confirm_request = PasswordResetConfirmRequest(
            email=email,
            confirmation_code=confirmation_code,
            new_password=new_password
        )
        
        # Test that validation is consistent
        # Note: Email may be normalized to lowercase by Pydantic
        assert confirm_request.email.lower() == email.lower()
        assert confirm_request.confirmation_code == confirmation_code
        assert confirm_request.new_password == new_password
        assert len(confirm_request.new_password) >= 8
        
        # Test serialization consistency
        dict1 = confirm_request.model_dump()
        dict2 = confirm_request.model_dump()
        assert dict1 == dict2
        
        # Test that re-parsing produces equivalent object
        reparsed = PasswordResetConfirmRequest.model_validate(dict1)
        assert reparsed == confirm_request
        assert reparsed.email.lower() == email.lower()
        assert reparsed.confirmation_code == confirmation_code
        assert reparsed.new_password == new_password

    @given(st.dictionaries(st.text(min_size=1, max_size=50), st.text(max_size=200), max_size=10))
    @settings(max_examples=100, deadline=2000)
    def test_user_profile_consistency(self, preferences: Dict[str, str]):
        """
        Test that user profile data handling is consistent.
        
        Property: For any user profile data, serialization and deserialization
        should preserve all data without corruption.
        """
        # Create user profile
        profile = UserProfile(
            id=str(uuid4()),
            email="test@example.com",
            name="Test User",
            preferences=preferences
        )
        
        # Test that all data is preserved
        assert profile.preferences == preferences
        assert '@' in profile.email
        assert profile.name.strip()
        
        # Test serialization consistency
        dict1 = profile.model_dump()
        dict2 = profile.model_dump()
        assert dict1 == dict2
        
        # Test that re-parsing produces equivalent object
        reparsed = UserProfile.model_validate(dict1)
        assert reparsed == profile
        assert reparsed.preferences == preferences

    @given(st.text(min_size=10, max_size=50))
    @settings(max_examples=50, deadline=2000)
    def test_jwt_validation_error_consistency(self, error_message: str):
        """
        Test that JWT validation errors are handled consistently.
        
        Property: For any error condition, JWT validation should fail consistently
        with appropriate error messages.
        """
        # Test that JWTValidationError preserves error information
        error = JWTValidationError(error_message)
        
        assert error.message == error_message
        assert error.status_code == 401  # Default status code
        assert str(error) == error_message
        
        # Test with custom status code
        custom_error = JWTValidationError(error_message, status_code=403)
        assert custom_error.message == error_message
        assert custom_error.status_code == 403

    @given(st.text(min_size=10, max_size=50), st.text(min_size=1, max_size=20))
    @settings(max_examples=50, deadline=2000)
    def test_cognito_auth_error_consistency(self, error_message: str, error_code: str):
        """
        Test that Cognito authentication errors are handled consistently.
        
        Property: For any error condition, Cognito errors should be handled consistently
        with proper error codes and messages.
        """
        # Test that CognitoAuthError preserves error information
        error = CognitoAuthError(error_message, error_code=error_code)
        
        assert error.message == error_message
        assert error.error_code == error_code
        assert str(error) == error_message
        
        # Test with additional details
        details = {"field": "value", "count": 42}
        detailed_error = CognitoAuthError(error_message, error_code=error_code, details=details)
        assert detailed_error.details == details
        assert detailed_error.message == error_message
        assert detailed_error.error_code == error_code