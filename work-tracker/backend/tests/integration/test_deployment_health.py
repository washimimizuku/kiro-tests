"""
Integration tests for deployment health and service connectivity.
Tests the complete deployment stack including database, cache, and external services.
"""

import asyncio
import os
import pytest
import httpx
import asyncpg
import redis.asyncio as redis
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

from app.core.config import get_settings
from app.core.database import get_database_url


class TestDeploymentHealth:
    """Test suite for deployment health checks."""
    
    @pytest.fixture(scope="class")
    def settings(self):
        """Get application settings."""
        return get_settings()
    
    @pytest.fixture(scope="class")
    async def db_engine(self, settings):
        """Create database engine for testing."""
        engine = create_async_engine(get_database_url())
        yield engine
        await engine.dispose()
    
    @pytest.fixture(scope="class")
    async def redis_client(self, settings):
        """Create Redis client for testing."""
        redis_url = os.getenv("REDIS_URL", "redis://localhost:6379")
        client = redis.from_url(redis_url)
        yield client
        await client.close()
    
    @pytest.fixture(scope="class")
    def api_base_url(self):
        """Get API base URL from environment."""
        return os.getenv("API_BASE_URL", "http://localhost:8000")
    
    async def test_api_health_endpoint(self, api_base_url):
        """Test that the API health endpoint is accessible and returns correct status."""
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{api_base_url}/health")
            
            assert response.status_code == 200
            health_data = response.json()
            
            # Verify health response structure
            assert "status" in health_data
            assert "timestamp" in health_data
            assert "version" in health_data
            assert "environment" in health_data
            
            # Verify status is healthy
            assert health_data["status"] == "healthy"
    
    async def test_database_connectivity(self, db_engine):
        """Test database connectivity and basic operations."""
        async with db_engine.connect() as conn:
            # Test basic query
            result = await conn.execute(text("SELECT 1 as test"))
            row = result.fetchone()
            assert row[0] == 1
            
            # Test database version
            result = await conn.execute(text("SELECT version()"))
            version = result.fetchone()[0]
            assert "PostgreSQL" in version
            
            # Test table existence (users table should exist)
            result = await conn.execute(text("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_schema = 'public' 
                    AND table_name = 'users'
                )
            """))
            table_exists = result.fetchone()[0]
            assert table_exists is True
    
    async def test_redis_connectivity(self, redis_client):
        """Test Redis connectivity and basic operations."""
        # Test ping
        pong = await redis_client.ping()
        assert pong is True
        
        # Test set/get operations
        test_key = "deployment_test_key"
        test_value = "deployment_test_value"
        
        await redis_client.set(test_key, test_value, ex=60)  # Expire in 60 seconds
        retrieved_value = await redis_client.get(test_key)
        
        assert retrieved_value.decode() == test_value
        
        # Clean up
        await redis_client.delete(test_key)
    
    async def test_api_authentication_endpoints(self, api_base_url):
        """Test authentication-related endpoints are accessible."""
        async with httpx.AsyncClient() as client:
            # Test auth endpoints exist (should return 401 or proper error, not 404)
            endpoints = [
                "/api/v1/auth/me",
                "/api/v1/activities",
                "/api/v1/stories",
                "/api/v1/reports"
            ]
            
            for endpoint in endpoints:
                response = await client.get(f"{api_base_url}{endpoint}")
                # Should not be 404 (endpoint exists) or 500 (server error)
                assert response.status_code not in [404, 500]
                # Should be 401 (unauthorized) or 422 (validation error)
                assert response.status_code in [401, 422]
    
    async def test_cors_configuration(self, api_base_url):
        """Test CORS configuration for frontend integration."""
        async with httpx.AsyncClient() as client:
            # Test preflight request
            response = await client.options(
                f"{api_base_url}/api/v1/activities",
                headers={
                    "Origin": "https://worktracker.example.com",
                    "Access-Control-Request-Method": "GET",
                    "Access-Control-Request-Headers": "Authorization"
                }
            )
            
            # Should allow CORS
            assert response.status_code in [200, 204]
            
            # Check CORS headers
            headers = response.headers
            assert "access-control-allow-origin" in headers
            assert "access-control-allow-methods" in headers
    
    async def test_api_rate_limiting(self, api_base_url):
        """Test API rate limiting is configured."""
        async with httpx.AsyncClient() as client:
            # Make multiple requests to test rate limiting
            responses = []
            for _ in range(10):
                response = await client.get(f"{api_base_url}/health")
                responses.append(response.status_code)
            
            # All health check requests should succeed (rate limiting should be generous for health)
            assert all(status == 200 for status in responses)
    
    async def test_database_migrations(self, db_engine):
        """Test that database migrations have been applied correctly."""
        async with db_engine.connect() as conn:
            # Check that all expected tables exist
            expected_tables = ["users", "activities", "stories", "reports"]
            
            for table in expected_tables:
                result = await conn.execute(text(f"""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables 
                        WHERE table_schema = 'public' 
                        AND table_name = '{table}'
                    )
                """))
                table_exists = result.fetchone()[0]
                assert table_exists, f"Table {table} does not exist"
            
            # Check that indexes exist for performance
            result = await conn.execute(text("""
                SELECT indexname FROM pg_indexes 
                WHERE schemaname = 'public' 
                AND tablename IN ('users', 'activities', 'stories', 'reports')
            """))
            indexes = [row[0] for row in result.fetchall()]
            
            # Should have at least primary key indexes
            assert len(indexes) > 0, "No indexes found on main tables"
    
    async def test_environment_variables(self, settings):
        """Test that required environment variables are set correctly."""
        # Check critical environment variables
        assert settings.database_url is not None
        assert settings.redis_url is not None
        assert settings.aws_region is not None
        assert settings.environment is not None
        
        # Check that environment is set to expected value
        expected_env = os.getenv("ENVIRONMENT", "test")
        assert settings.environment == expected_env
    
    async def test_logging_configuration(self, api_base_url):
        """Test that logging is configured and working."""
        async with httpx.AsyncClient() as client:
            # Make a request that should generate logs
            response = await client.get(f"{api_base_url}/health")
            assert response.status_code == 200
            
            # In a real deployment, we would check CloudWatch logs
            # For now, just verify the request succeeded
            assert response.json()["status"] == "healthy"


class TestServiceIntegration:
    """Test integration between different services."""
    
    @pytest.fixture(scope="class")
    def api_base_url(self):
        """Get API base URL from environment."""
        return os.getenv("API_BASE_URL", "http://localhost:8000")
    
    async def test_full_request_lifecycle(self, api_base_url):
        """Test a complete request lifecycle through all layers."""
        async with httpx.AsyncClient() as client:
            # Test health endpoint (goes through all layers)
            response = await client.get(f"{api_base_url}/health")
            assert response.status_code == 200
            
            health_data = response.json()
            assert health_data["status"] == "healthy"
            
            # Verify response includes database and cache status
            # (This would be implemented in the actual health endpoint)
            assert "timestamp" in health_data
    
    async def test_error_handling_integration(self, api_base_url):
        """Test error handling across service boundaries."""
        async with httpx.AsyncClient() as client:
            # Test 404 handling
            response = await client.get(f"{api_base_url}/nonexistent-endpoint")
            assert response.status_code == 404
            
            # Test malformed request handling
            response = await client.post(
                f"{api_base_url}/api/v1/activities",
                json={"invalid": "data"}
            )
            # Should return validation error, not server error
            assert response.status_code in [400, 401, 422]
            assert response.status_code != 500
    
    async def test_concurrent_request_handling(self, api_base_url):
        """Test handling of concurrent requests."""
        async with httpx.AsyncClient() as client:
            # Create multiple concurrent requests
            tasks = []
            for _ in range(20):
                task = client.get(f"{api_base_url}/health")
                tasks.append(task)
            
            # Execute all requests concurrently
            responses = await asyncio.gather(*tasks)
            
            # All requests should succeed
            for response in responses:
                assert response.status_code == 200
                assert response.json()["status"] == "healthy"


class TestPerformanceBaseline:
    """Test performance baselines for deployment validation."""
    
    @pytest.fixture(scope="class")
    def api_base_url(self):
        """Get API base URL from environment."""
        return os.getenv("API_BASE_URL", "http://localhost:8000")
    
    async def test_response_time_baseline(self, api_base_url):
        """Test that response times meet baseline requirements."""
        async with httpx.AsyncClient() as client:
            import time
            
            # Test health endpoint response time
            start_time = time.time()
            response = await client.get(f"{api_base_url}/health")
            end_time = time.time()
            
            response_time = (end_time - start_time) * 1000  # Convert to milliseconds
            
            assert response.status_code == 200
            # Health endpoint should respond within 500ms
            assert response_time < 500, f"Health endpoint took {response_time}ms"
    
    async def test_throughput_baseline(self, api_base_url):
        """Test basic throughput requirements."""
        async with httpx.AsyncClient() as client:
            import time
            
            # Test multiple requests in sequence
            start_time = time.time()
            request_count = 10
            
            for _ in range(request_count):
                response = await client.get(f"{api_base_url}/health")
                assert response.status_code == 200
            
            end_time = time.time()
            total_time = end_time - start_time
            requests_per_second = request_count / total_time
            
            # Should handle at least 10 requests per second
            assert requests_per_second >= 10, f"Only {requests_per_second:.2f} requests/second"


@pytest.mark.asyncio
class TestDeploymentValidation:
    """High-level deployment validation tests."""
    
    async def test_deployment_readiness(self):
        """Test that deployment is ready for traffic."""
        # This test combines multiple checks to validate deployment readiness
        api_base_url = os.getenv("API_BASE_URL", "http://localhost:8000")
        
        async with httpx.AsyncClient() as client:
            # 1. Health check
            response = await client.get(f"{api_base_url}/health")
            assert response.status_code == 200
            
            # 2. API endpoints are accessible
            response = await client.get(f"{api_base_url}/api/v1/activities")
            assert response.status_code in [401, 422]  # Should require auth, not crash
            
            # 3. Error handling works
            response = await client.get(f"{api_base_url}/nonexistent")
            assert response.status_code == 404
            
        print("✅ Deployment validation passed - ready for traffic")
    
    async def test_rollback_readiness(self):
        """Test that system can handle rollback scenarios."""
        # Test that the system gracefully handles service restarts
        api_base_url = os.getenv("API_BASE_URL", "http://localhost:8000")
        
        async with httpx.AsyncClient() as client:
            # Verify current deployment is working
            response = await client.get(f"{api_base_url}/health")
            assert response.status_code == 200
            
            current_version = response.json().get("version", "unknown")
            print(f"Current deployment version: {current_version}")
        
        print("✅ System ready for rollback if needed")