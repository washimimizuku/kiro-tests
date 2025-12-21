"""
AWS Bedrock client configuration and management.
"""
import json
import logging
from typing import Dict, Any, Optional
import boto3
from botocore.exceptions import ClientError, BotoCoreError
from botocore.config import Config
import asyncio
from functools import wraps
import time

from app.core.config import settings

logger = logging.getLogger(__name__)


class BedrockClientError(Exception):
    """Custom exception for Bedrock client errors."""
    pass


def retry_with_exponential_backoff(max_retries: int = 3, base_delay: float = 1.0):
    """Decorator for exponential backoff retry logic."""
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(max_retries):
                try:
                    return await func(*args, **kwargs)
                except (ClientError, BotoCoreError) as e:
                    last_exception = e
                    if attempt == max_retries - 1:
                        break
                    
                    delay = base_delay * (2 ** attempt)
                    logger.warning(
                        f"Bedrock API call failed (attempt {attempt + 1}/{max_retries}): {e}. "
                        f"Retrying in {delay} seconds..."
                    )
                    await asyncio.sleep(delay)
            
            logger.error(f"Bedrock API call failed after {max_retries} attempts: {last_exception}")
            raise BedrockClientError(f"Failed after {max_retries} attempts: {last_exception}")
        
        return wrapper
    return decorator


class BedrockClient:
    """AWS Bedrock client with retry logic and error handling."""
    
    def __init__(self):
        """Initialize Bedrock client with configuration."""
        self.config = Config(
            region_name=settings.AWS_REGION,
            retries={'max_attempts': 3, 'mode': 'adaptive'},
            max_pool_connections=50
        )
        
        self.bedrock_runtime = boto3.client(
            'bedrock-runtime',
            config=self.config,
            aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY
        )
        
        # Model configurations
        self.claude_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"
        self.max_tokens = 4000
        self.temperature = 0.7
        
        logger.info("Bedrock client initialized successfully")
    
    @retry_with_exponential_backoff(max_retries=3)
    async def invoke_claude(
        self, 
        prompt: str, 
        system_prompt: Optional[str] = None,
        max_tokens: Optional[int] = None,
        temperature: Optional[float] = None
    ) -> str:
        """
        Invoke Claude model with the given prompt.
        
        Args:
            prompt: The user prompt to send to Claude
            system_prompt: Optional system prompt for context
            max_tokens: Maximum tokens to generate (default: 4000)
            temperature: Temperature for response generation (default: 0.7)
            
        Returns:
            Generated text response from Claude
            
        Raises:
            BedrockClientError: If the API call fails after retries
        """
        try:
            # Prepare the request body
            messages = []
            if system_prompt:
                messages.append({
                    "role": "system",
                    "content": system_prompt
                })
            
            messages.append({
                "role": "user", 
                "content": prompt
            })
            
            body = {
                "anthropic_version": "bedrock-2023-05-31",
                "max_tokens": max_tokens or self.max_tokens,
                "temperature": temperature or self.temperature,
                "messages": messages
            }
            
            # Make the API call
            response = self.bedrock_runtime.invoke_model(
                modelId=self.claude_model_id,
                body=json.dumps(body),
                contentType='application/json',
                accept='application/json'
            )
            
            # Parse the response
            response_body = json.loads(response['body'].read())
            
            if 'content' in response_body and response_body['content']:
                return response_body['content'][0]['text']
            else:
                raise BedrockClientError("No content in response")
                
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            logger.error(f"Bedrock ClientError: {error_code} - {error_message}")
            raise BedrockClientError(f"AWS API Error: {error_code} - {error_message}")
        
        except BotoCoreError as e:
            logger.error(f"Bedrock BotoCoreError: {e}")
            raise BedrockClientError(f"AWS Connection Error: {e}")
        
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Bedrock response: {e}")
            raise BedrockClientError(f"Response parsing error: {e}")
        
        except Exception as e:
            logger.error(f"Unexpected error in Bedrock call: {e}")
            raise BedrockClientError(f"Unexpected error: {e}")
    
    async def health_check(self) -> bool:
        """
        Perform a health check on the Bedrock service.
        
        Returns:
            True if the service is healthy, False otherwise
        """
        try:
            test_prompt = "Hello, this is a health check. Please respond with 'OK'."
            response = await self.invoke_claude(test_prompt, max_tokens=10)
            return "OK" in response.upper()
        except Exception as e:
            logger.error(f"Bedrock health check failed: {e}")
            return False


# Global client instance
_bedrock_client: Optional[BedrockClient] = None


def get_bedrock_client() -> BedrockClient:
    """Get or create the global Bedrock client instance."""
    global _bedrock_client
    if _bedrock_client is None:
        _bedrock_client = BedrockClient()
    return _bedrock_client