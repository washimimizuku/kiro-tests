"""
AWS Cognito Client

Service for interacting with AWS Cognito for user authentication and management.
"""

import boto3
import hmac
import hashlib
import base64
from typing import Dict, Any, Optional
from botocore.exceptions import ClientError
import structlog

from app.core.config import settings

logger = structlog.get_logger()


class CognitoAuthError(Exception):
    """Custom exception for Cognito authentication errors."""
    
    def __init__(self, message: str, error_code: str = None, details: Dict[str, Any] = None):
        self.message = message
        self.error_code = error_code
        self.details = details or {}
        super().__init__(self.message)


class CognitoClient:
    """AWS Cognito client for user authentication operations."""
    
    def __init__(self):
        """Initialize Cognito client with AWS credentials."""
        self.client = boto3.client(
            'cognito-idp',
            region_name=settings.AWS_REGION,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
        )
        self.user_pool_id = settings.COGNITO_USER_POOL_ID
        self.client_id = settings.COGNITO_CLIENT_ID
        self.client_secret = settings.COGNITO_CLIENT_SECRET
        
        if not all([self.user_pool_id, self.client_id]):
            logger.warning("Cognito configuration incomplete - some features may not work")
    
    def _calculate_secret_hash(self, username: str) -> str:
        """Calculate the secret hash for Cognito client authentication."""
        if not self.client_secret:
            return None
            
        message = username + self.client_id
        dig = hmac.new(
            str(self.client_secret).encode('utf-8'),
            msg=str(message).encode('utf-8'),
            digestmod=hashlib.sha256
        ).digest()
        return base64.b64encode(dig).decode()
    
    async def authenticate_user(self, email: str, password: str) -> Dict[str, Any]:
        """
        Authenticate user with email and password.
        
        Args:
            email: User email address
            password: User password
            
        Returns:
            Dict containing authentication tokens and user info
            
        Raises:
            CognitoAuthError: If authentication fails
        """
        try:
            auth_params = {
                'USERNAME': email,
                'PASSWORD': password,
            }
            
            # Add secret hash if client secret is configured
            secret_hash = self._calculate_secret_hash(email)
            if secret_hash:
                auth_params['SECRET_HASH'] = secret_hash
            
            response = self.client.initiate_auth(
                ClientId=self.client_id,
                AuthFlow='USER_PASSWORD_AUTH',
                AuthParameters=auth_params
            )
            
            # Handle different authentication challenges
            if 'ChallengeName' in response:
                challenge_name = response['ChallengeName']
                logger.info(f"Authentication challenge required: {challenge_name}")
                raise CognitoAuthError(
                    f"Authentication challenge required: {challenge_name}",
                    error_code="CHALLENGE_REQUIRED",
                    details={'challenge': challenge_name, 'session': response.get('Session')}
                )
            
            auth_result = response['AuthenticationResult']
            
            # Get user attributes
            user_info = await self.get_user_info(auth_result['AccessToken'])
            
            return {
                'access_token': auth_result['AccessToken'],
                'refresh_token': auth_result.get('RefreshToken'),
                'id_token': auth_result.get('IdToken'),
                'token_type': auth_result.get('TokenType', 'Bearer'),
                'expires_in': auth_result.get('ExpiresIn', 3600),
                'user_info': user_info
            }
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            
            logger.error(
                "Cognito authentication failed",
                error_code=error_code,
                error_message=error_message,
                email=email
            )
            
            # Map Cognito errors to user-friendly messages
            if error_code == 'NotAuthorizedException':
                raise CognitoAuthError(
                    "Invalid email or password",
                    error_code="INVALID_CREDENTIALS"
                )
            elif error_code == 'UserNotConfirmedException':
                raise CognitoAuthError(
                    "User account not confirmed. Please check your email for confirmation instructions.",
                    error_code="USER_NOT_CONFIRMED"
                )
            elif error_code == 'UserNotFoundException':
                raise CognitoAuthError(
                    "User account not found",
                    error_code="USER_NOT_FOUND"
                )
            elif error_code == 'TooManyRequestsException':
                raise CognitoAuthError(
                    "Too many login attempts. Please try again later.",
                    error_code="TOO_MANY_REQUESTS"
                )
            else:
                raise CognitoAuthError(
                    f"Authentication failed: {error_message}",
                    error_code=error_code
                )
    
    async def refresh_token(self, refresh_token: str) -> Dict[str, Any]:
        """
        Refresh access token using refresh token.
        
        Args:
            refresh_token: Valid refresh token
            
        Returns:
            Dict containing new authentication tokens
            
        Raises:
            CognitoAuthError: If token refresh fails
        """
        try:
            auth_params = {
                'REFRESH_TOKEN': refresh_token,
            }
            
            # Add secret hash if client secret is configured
            if self.client_secret:
                # For refresh token, we need to get the username first
                # This is a limitation - we'll need to store username with refresh token
                # For now, we'll proceed without secret hash for refresh
                pass
            
            response = self.client.initiate_auth(
                ClientId=self.client_id,
                AuthFlow='REFRESH_TOKEN_AUTH',
                AuthParameters=auth_params
            )
            
            auth_result = response['AuthenticationResult']
            
            return {
                'access_token': auth_result['AccessToken'],
                'id_token': auth_result.get('IdToken'),
                'token_type': auth_result.get('TokenType', 'Bearer'),
                'expires_in': auth_result.get('ExpiresIn', 3600)
            }
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            
            logger.error(
                "Token refresh failed",
                error_code=error_code,
                error_message=error_message
            )
            
            if error_code == 'NotAuthorizedException':
                raise CognitoAuthError(
                    "Invalid or expired refresh token",
                    error_code="INVALID_REFRESH_TOKEN"
                )
            else:
                raise CognitoAuthError(
                    f"Token refresh failed: {error_message}",
                    error_code=error_code
                )
    
    async def get_user_info(self, access_token: str) -> Dict[str, Any]:
        """
        Get user information from access token.
        
        Args:
            access_token: Valid access token
            
        Returns:
            Dict containing user information
            
        Raises:
            CognitoAuthError: If user info retrieval fails
        """
        try:
            response = self.client.get_user(AccessToken=access_token)
            
            # Parse user attributes
            user_attributes = {}
            for attr in response.get('UserAttributes', []):
                user_attributes[attr['Name']] = attr['Value']
            
            return {
                'username': response['Username'],
                'email': user_attributes.get('email'),
                'name': user_attributes.get('name'),
                'email_verified': user_attributes.get('email_verified') == 'true',
                'user_status': response.get('UserStatus'),
                'attributes': user_attributes
            }
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            
            logger.error(
                "Get user info failed",
                error_code=error_code,
                error_message=error_message
            )
            
            raise CognitoAuthError(
                f"Failed to get user information: {error_message}",
                error_code=error_code
            )
    
    async def register_user(self, email: str, password: str, name: str) -> Dict[str, Any]:
        """
        Register a new user in Cognito.
        
        Args:
            email: User email address
            password: User password
            name: User full name
            
        Returns:
            Dict containing registration result
            
        Raises:
            CognitoAuthError: If registration fails
        """
        try:
            user_attributes = [
                {'Name': 'email', 'Value': email},
                {'Name': 'name', 'Value': name},
            ]
            
            auth_params = {
                'Username': email,
                'Password': password,
                'UserAttributes': user_attributes,
            }
            
            # Add secret hash if client secret is configured
            secret_hash = self._calculate_secret_hash(email)
            if secret_hash:
                auth_params['SecretHash'] = secret_hash
            
            response = self.client.sign_up(
                ClientId=self.client_id,
                **auth_params
            )
            
            return {
                'user_sub': response['UserSub'],
                'confirmation_required': not response.get('UserConfirmed', False),
                'delivery_details': response.get('CodeDeliveryDetails')
            }
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            
            logger.error(
                "User registration failed",
                error_code=error_code,
                error_message=error_message,
                email=email
            )
            
            if error_code == 'UsernameExistsException':
                raise CognitoAuthError(
                    "An account with this email already exists",
                    error_code="USER_EXISTS"
                )
            elif error_code == 'InvalidPasswordException':
                raise CognitoAuthError(
                    "Password does not meet requirements",
                    error_code="INVALID_PASSWORD"
                )
            else:
                raise CognitoAuthError(
                    f"Registration failed: {error_message}",
                    error_code=error_code
                )
    
    async def initiate_password_reset(self, email: str) -> Dict[str, Any]:
        """
        Initiate password reset for user.
        
        Args:
            email: User email address
            
        Returns:
            Dict containing password reset initiation result
            
        Raises:
            CognitoAuthError: If password reset initiation fails
        """
        try:
            auth_params = {
                'Username': email,
            }
            
            # Add secret hash if client secret is configured
            secret_hash = self._calculate_secret_hash(email)
            if secret_hash:
                auth_params['SecretHash'] = secret_hash
            
            response = self.client.forgot_password(
                ClientId=self.client_id,
                **auth_params
            )
            
            return {
                'delivery_details': response.get('CodeDeliveryDetails')
            }
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            
            logger.error(
                "Password reset initiation failed",
                error_code=error_code,
                error_message=error_message,
                email=email
            )
            
            if error_code == 'UserNotFoundException':
                # For security, don't reveal if user exists
                return {'delivery_details': None}
            else:
                raise CognitoAuthError(
                    f"Password reset failed: {error_message}",
                    error_code=error_code
                )
    
    async def confirm_password_reset(self, email: str, confirmation_code: str, new_password: str) -> bool:
        """
        Confirm password reset with verification code.
        
        Args:
            email: User email address
            confirmation_code: Verification code from email
            new_password: New password
            
        Returns:
            True if password reset successful
            
        Raises:
            CognitoAuthError: If password reset confirmation fails
        """
        try:
            auth_params = {
                'Username': email,
                'ConfirmationCode': confirmation_code,
                'Password': new_password,
            }
            
            # Add secret hash if client secret is configured
            secret_hash = self._calculate_secret_hash(email)
            if secret_hash:
                auth_params['SecretHash'] = secret_hash
            
            self.client.confirm_forgot_password(
                ClientId=self.client_id,
                **auth_params
            )
            
            return True
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            
            logger.error(
                "Password reset confirmation failed",
                error_code=error_code,
                error_message=error_message,
                email=email
            )
            
            if error_code == 'CodeMismatchException':
                raise CognitoAuthError(
                    "Invalid verification code",
                    error_code="INVALID_CODE"
                )
            elif error_code == 'ExpiredCodeException':
                raise CognitoAuthError(
                    "Verification code has expired",
                    error_code="EXPIRED_CODE"
                )
            elif error_code == 'InvalidPasswordException':
                raise CognitoAuthError(
                    "Password does not meet requirements",
                    error_code="INVALID_PASSWORD"
                )
            else:
                raise CognitoAuthError(
                    f"Password reset confirmation failed: {error_message}",
                    error_code=error_code
                )


# Global Cognito client instance
cognito_client = CognitoClient()