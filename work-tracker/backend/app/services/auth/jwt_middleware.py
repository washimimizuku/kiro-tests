"""
JWT Token Validation Middleware

Middleware for validating JWT tokens from AWS Cognito and extracting user information.
"""

import jwt
import json
import httpx
from typing import Optional, Dict, Any
from fastapi import HTTPException, status, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import structlog

from app.core.config import settings
from app.services.auth.cognito_client import CognitoAuthError

logger = structlog.get_logger()

# HTTP Bearer token scheme
security = HTTPBearer()


class JWTValidationError(Exception):
    """Custom exception for JWT validation errors."""
    
    def __init__(self, message: str, status_code: int = status.HTTP_401_UNAUTHORIZED):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class JWTValidator:
    """JWT token validator for AWS Cognito tokens."""
    
    def __init__(self):
        """Initialize JWT validator."""
        self.jwks_cache: Optional[Dict[str, Any]] = None
        self.user_pool_id = settings.COGNITO_USER_POOL_ID
        self.client_id = settings.COGNITO_CLIENT_ID
        
        if not self.user_pool_id:
            logger.warning("Cognito User Pool ID not configured - JWT validation will be disabled")
    
    async def get_jwks(self) -> Dict[str, Any]:
        """
        Get JSON Web Key Set (JWKS) from Cognito.
        
        Returns:
            JWKS dictionary
            
        Raises:
            JWTValidationError: If JWKS retrieval fails
        """
        if self.jwks_cache:
            return self.jwks_cache
        
        if not self.user_pool_id:
            raise JWTValidationError("Cognito configuration not available")
        
        try:
            jwks_url = f"https://cognito-idp.{settings.AWS_REGION}.amazonaws.com/{self.user_pool_id}/.well-known/jwks.json"
            
            async with httpx.AsyncClient() as client:
                response = await client.get(jwks_url)
                response.raise_for_status()
                
                self.jwks_cache = response.json()
                return self.jwks_cache
                
        except Exception as e:
            logger.error(f"Failed to retrieve JWKS: {str(e)}")
            raise JWTValidationError("Failed to retrieve token validation keys")
    
    def get_signing_key(self, token_header: Dict[str, Any], jwks: Dict[str, Any]) -> str:
        """
        Get the signing key for token validation.
        
        Args:
            token_header: JWT token header
            jwks: JSON Web Key Set
            
        Returns:
            Signing key for token validation
            
        Raises:
            JWTValidationError: If signing key not found
        """
        kid = token_header.get('kid')
        if not kid:
            raise JWTValidationError("Token missing key ID")
        
        for key in jwks.get('keys', []):
            if key.get('kid') == kid:
                # Convert JWK to PEM format for PyJWT
                from jwt.algorithms import RSAAlgorithm
                return RSAAlgorithm.from_jwk(json.dumps(key))
        
        raise JWTValidationError("Signing key not found")
    
    async def validate_token(self, token: str) -> Dict[str, Any]:
        """
        Validate JWT token and extract claims.
        
        Args:
            token: JWT token string
            
        Returns:
            Token claims dictionary
            
        Raises:
            JWTValidationError: If token validation fails
        """
        try:
            # Decode token header without verification to get key ID
            unverified_header = jwt.get_unverified_header(token)
            
            # Get JWKS and signing key
            jwks = await self.get_jwks()
            signing_key = self.get_signing_key(unverified_header, jwks)
            
            # Verify and decode token
            claims = jwt.decode(
                token,
                signing_key,
                algorithms=['RS256'],
                audience=self.client_id,
                issuer=f"https://cognito-idp.{settings.AWS_REGION}.amazonaws.com/{self.user_pool_id}"
            )
            
            # Validate token type
            token_use = claims.get('token_use')
            if token_use not in ['access', 'id']:
                raise JWTValidationError("Invalid token type")
            
            return claims
            
        except jwt.ExpiredSignatureError:
            raise JWTValidationError("Token has expired")
        except jwt.InvalidTokenError as e:
            logger.error(f"Token validation failed: {str(e)}")
            raise JWTValidationError("Invalid token")
        except Exception as e:
            logger.error(f"Unexpected error during token validation: {str(e)}")
            raise JWTValidationError("Token validation failed")


# Global JWT validator instance
jwt_validator = JWTValidator()


async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """
    Dependency to get current authenticated user from JWT token.
    
    Args:
        credentials: HTTP authorization credentials
        
    Returns:
        User information from token claims
        
    Raises:
        HTTPException: If authentication fails
    """
    try:
        # Extract token from credentials
        token = credentials.credentials
        
        # Validate token and get claims
        claims = await jwt_validator.validate_token(token)
        
        # Extract user information from claims
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
        
        return user_info
        
    except JWTValidationError as e:
        logger.warning(f"Authentication failed: {e.message}")
        raise HTTPException(
            status_code=e.status_code,
            detail=e.message,
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as e:
        logger.error(f"Unexpected authentication error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Authentication service error"
        )


async def get_optional_user(credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)) -> Optional[Dict[str, Any]]:
    """
    Dependency to get current user if authenticated, None otherwise.
    
    Args:
        credentials: Optional HTTP authorization credentials
        
    Returns:
        User information if authenticated, None otherwise
    """
    if not credentials:
        return None
    
    try:
        return await get_current_user(credentials)
    except HTTPException:
        return None