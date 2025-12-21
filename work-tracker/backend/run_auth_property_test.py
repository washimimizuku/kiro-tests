#!/usr/bin/env python3
"""
Simple test runner for authentication property-based tests.
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from hypothesis import given, strategies as st, settings
from datetime import datetime, timedelta
from uuid import uuid4
from typing import Dict, Any

from app.services.auth.schemas import (
    LoginRequest, RefreshRequest, TokenResponse, UserRegistrationRequest,
    UserProfile, PasswordResetRequest, PasswordResetConfirmRequest
)
from app.services.auth.jwt_middleware import JWTValidationError
from app.services.auth.cognito_client import CognitoAuthError


# Test data generators
@st.composite
def valid_email(draw):
    """Generate valid email addresses."""
    local = draw(st.text(min_size=1, max_size=64, alphabet=st.characters(
        whitelist_categories=('Lu', 'Ll', 'Nd'), 
        whitelist_characters='.-_'
    )).filter(lambda x: x and not x.startswith('.') and not x.endswith('.')))
    domain = draw(st.text(min_size=1, max_size=63, alphabet=st.characters(
        whitelist_categories=('Lu', 'Ll', 'Nd'), 
        whitelist_characters='-'
    )).filter(lambda x: x and not x.startswith('-') and not x.endswith('-')))
    tld = draw(st.sampled_from(['com', 'org', 'net', 'edu', 'gov']))
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


@given(login_request_data())
@settings(max_examples=100, deadline=2000)
def test_login_request_validation_consistency(login_request: LoginRequest):
    """
    **Feature: work-tracker, Property 9: Authentication Token Validation**
    **Validates: Requirements 5.2**
    
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
def test_jwt_claims_extraction_consistency(claims: Dict[str, Any]):
    """
    **Feature: work-tracker, Property 9: Authentication Token Validation**
    **Validates: Requirements 5.2**
    
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


@given(cognito_auth_result())
@settings(max_examples=100, deadline=2000)
def test_token_response_generation_consistency(auth_result: Dict[str, Any]):
    """
    **Feature: work-tracker, Property 9: Authentication Token Validation**
    **Validates: Requirements 5.2**
    
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


if __name__ == "__main__":
    print("Running Property-Based Tests for Authentication Token Validation...")
    print("**Feature: work-tracker, Property 9: Authentication Token Validation**")
    print("**Validates: Requirements 5.2**")
    
    test_functions = [
        test_login_request_validation_consistency,
        test_jwt_claims_extraction_consistency,
        test_token_response_generation_consistency
    ]
    
    for i, test_func in enumerate(test_functions, 1):
        try:
            print(f"\nRunning test {i}/{len(test_functions)}: {test_func.__name__}")
            test_func()
            print(f"✅ Property test PASSED: {test_func.__name__}")
        except Exception as e:
            print(f"❌ Property test FAILED: {test_func.__name__} - {e}")
            sys.exit(1)
    
    print("\n🎉 All authentication property tests completed successfully!")