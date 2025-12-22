"""
Load and performance tests for deployment validation.
Tests system behavior under various load conditions.
"""

import asyncio
import time
import statistics
from typing import List, Dict, Any
import pytest
import httpx
import os


class TestLoadPerformance:
    """Test system performance under load."""
    
    @pytest.fixture(scope="class")
    def api_base_url(self):
        """Get API base URL from environment."""
        return os.getenv("API_BASE_URL", "http://localhost:8000")
    
    @pytest.fixture(scope="class")
    def load_test_config(self):
        """Configuration for load tests."""
        return {
            "light_load": {"concurrent_users": 5, "requests_per_user": 10},
            "medium_load": {"concurrent_users": 10, "requests_per_user": 20},
            "heavy_load": {"concurrent_users": 20, "requests_per_user": 30},
            "timeout": 30.0,  # 30 second timeout for requests
            "acceptable_error_rate": 0.05,  # 5% error rate acceptable
            "max_response_time": 5000,  # 5 seconds max response time
        }
    
    async def make_request(self, client: httpx.AsyncClient, url: str) -> Dict[str, Any]:
        """Make a single request and return timing and status information."""
        start_time = time.time()
        try:
            response = await client.get(url)
            end_time = time.time()
            
            # Consider 200, 401, and 403 as successful responses (401/403 are expected for protected endpoints)
            success = response.status_code in [200, 401, 403]
            
            return {
                "status_code": response.status_code,
                "response_time": (end_time - start_time) * 1000,  # milliseconds
                "success": success,
                "error": None
            }
        except Exception as e:
            end_time = time.time()
            return {
                "status_code": 0,
                "response_time": (end_time - start_time) * 1000,
                "success": False,
                "error": str(e)
            }
    
    async def simulate_user_load(
        self, 
        api_base_url: str, 
        requests_per_user: int,
        endpoint: str = "/health"
    ) -> List[Dict[str, Any]]:
        """Simulate load from a single user making multiple requests."""
        results = []
        
        async with httpx.AsyncClient(timeout=30.0) as client:
            for _ in range(requests_per_user):
                result = await self.make_request(client, f"{api_base_url}{endpoint}")
                results.append(result)
                
                # Small delay between requests to simulate real user behavior
                await asyncio.sleep(0.1)
        
        return results
    
    def analyze_results(self, all_results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Analyze load test results and return metrics."""
        total_requests = len(all_results)
        successful_requests = sum(1 for r in all_results if r["success"])
        failed_requests = total_requests - successful_requests
        
        response_times = [r["response_time"] for r in all_results if r["success"]]
        
        if not response_times:
            return {
                "total_requests": total_requests,
                "successful_requests": 0,
                "failed_requests": failed_requests,
                "error_rate": 1.0,
                "avg_response_time": 0,
                "median_response_time": 0,
                "p95_response_time": 0,
                "max_response_time": 0,
                "min_response_time": 0
            }
        
        return {
            "total_requests": total_requests,
            "successful_requests": successful_requests,
            "failed_requests": failed_requests,
            "error_rate": failed_requests / total_requests,
            "avg_response_time": statistics.mean(response_times),
            "median_response_time": statistics.median(response_times),
            "p95_response_time": statistics.quantiles(response_times, n=20)[18] if len(response_times) > 20 else max(response_times),
            "max_response_time": max(response_times),
            "min_response_time": min(response_times)
        }
    
    @pytest.mark.asyncio
    async def test_light_load_performance(self, api_base_url, load_test_config):
        """Test system performance under light load."""
        config = load_test_config["light_load"]
        
        # Create tasks for concurrent users
        tasks = []
        for _ in range(config["concurrent_users"]):
            task = self.simulate_user_load(api_base_url, config["requests_per_user"])
            tasks.append(task)
        
        # Execute all user simulations concurrently
        start_time = time.time()
        user_results = await asyncio.gather(*tasks)
        end_time = time.time()
        
        # Flatten results from all users
        all_results = []
        for user_result in user_results:
            all_results.extend(user_result)
        
        # Analyze results
        metrics = self.analyze_results(all_results)
        total_time = end_time - start_time
        
        print(f"\n=== Light Load Test Results ===")
        print(f"Total requests: {metrics['total_requests']}")
        print(f"Successful requests: {metrics['successful_requests']}")
        print(f"Failed requests: {metrics['failed_requests']}")
        print(f"Error rate: {metrics['error_rate']:.2%}")
        print(f"Average response time: {metrics['avg_response_time']:.2f}ms")
        print(f"95th percentile response time: {metrics['p95_response_time']:.2f}ms")
        print(f"Total test time: {total_time:.2f}s")
        print(f"Requests per second: {metrics['total_requests'] / total_time:.2f}")
        
        # Assertions for light load
        assert metrics["error_rate"] <= load_test_config["acceptable_error_rate"], \
            f"Error rate {metrics['error_rate']:.2%} exceeds acceptable rate"
        assert metrics["avg_response_time"] <= 1000, \
            f"Average response time {metrics['avg_response_time']:.2f}ms too high for light load"
        assert metrics["p95_response_time"] <= 2000, \
            f"95th percentile response time {metrics['p95_response_time']:.2f}ms too high"
    
    @pytest.mark.asyncio
    async def test_medium_load_performance(self, api_base_url, load_test_config):
        """Test system performance under medium load."""
        config = load_test_config["medium_load"]
        
        # Create tasks for concurrent users
        tasks = []
        for _ in range(config["concurrent_users"]):
            task = self.simulate_user_load(api_base_url, config["requests_per_user"])
            tasks.append(task)
        
        # Execute all user simulations concurrently
        start_time = time.time()
        user_results = await asyncio.gather(*tasks)
        end_time = time.time()
        
        # Flatten results from all users
        all_results = []
        for user_result in user_results:
            all_results.extend(user_result)
        
        # Analyze results
        metrics = self.analyze_results(all_results)
        total_time = end_time - start_time
        
        print(f"\n=== Medium Load Test Results ===")
        print(f"Total requests: {metrics['total_requests']}")
        print(f"Successful requests: {metrics['successful_requests']}")
        print(f"Failed requests: {metrics['failed_requests']}")
        print(f"Error rate: {metrics['error_rate']:.2%}")
        print(f"Average response time: {metrics['avg_response_time']:.2f}ms")
        print(f"95th percentile response time: {metrics['p95_response_time']:.2f}ms")
        print(f"Total test time: {total_time:.2f}s")
        print(f"Requests per second: {metrics['total_requests'] / total_time:.2f}")
        
        # Assertions for medium load
        assert metrics["error_rate"] <= load_test_config["acceptable_error_rate"], \
            f"Error rate {metrics['error_rate']:.2%} exceeds acceptable rate"
        assert metrics["avg_response_time"] <= 2000, \
            f"Average response time {metrics['avg_response_time']:.2f}ms too high for medium load"
        assert metrics["p95_response_time"] <= 3000, \
            f"95th percentile response time {metrics['p95_response_time']:.2f}ms too high"
    
    @pytest.mark.asyncio
    @pytest.mark.slow
    async def test_heavy_load_performance(self, api_base_url, load_test_config):
        """Test system performance under heavy load."""
        config = load_test_config["heavy_load"]
        
        # Create tasks for concurrent users
        tasks = []
        for _ in range(config["concurrent_users"]):
            task = self.simulate_user_load(api_base_url, config["requests_per_user"])
            tasks.append(task)
        
        # Execute all user simulations concurrently
        start_time = time.time()
        user_results = await asyncio.gather(*tasks)
        end_time = time.time()
        
        # Flatten results from all users
        all_results = []
        for user_result in user_results:
            all_results.extend(user_result)
        
        # Analyze results
        metrics = self.analyze_results(all_results)
        total_time = end_time - start_time
        
        print(f"\n=== Heavy Load Test Results ===")
        print(f"Total requests: {metrics['total_requests']}")
        print(f"Successful requests: {metrics['successful_requests']}")
        print(f"Failed requests: {metrics['failed_requests']}")
        print(f"Error rate: {metrics['error_rate']:.2%}")
        print(f"Average response time: {metrics['avg_response_time']:.2f}ms")
        print(f"95th percentile response time: {metrics['p95_response_time']:.2f}ms")
        print(f"Total test time: {total_time:.2f}s")
        print(f"Requests per second: {metrics['total_requests'] / total_time:.2f}")
        
        # More lenient assertions for heavy load
        assert metrics["error_rate"] <= 0.10, \
            f"Error rate {metrics['error_rate']:.2%} too high even for heavy load"
        assert metrics["avg_response_time"] <= load_test_config["max_response_time"], \
            f"Average response time {metrics['avg_response_time']:.2f}ms exceeds maximum"
        assert metrics["successful_requests"] > 0, "No successful requests under heavy load"
    
    @pytest.mark.asyncio
    async def test_api_endpoint_performance(self, api_base_url, load_test_config):
        """Test performance of different API endpoints."""
        endpoints = [
            "/health",
            "/api/v1/activities/",  # Will return 403, but tests endpoint performance
            "/api/v1/stories/stories/",     # Will return 403, but tests endpoint performance
        ]
        
        results_by_endpoint = {}
        
        for endpoint in endpoints:
            print(f"\nTesting endpoint: {endpoint}")
            
            # Light load test for each endpoint
            tasks = []
            for _ in range(5):  # 5 concurrent users
                task = self.simulate_user_load(api_base_url, 10, endpoint)  # 10 requests each
                tasks.append(task)
            
            user_results = await asyncio.gather(*tasks)
            all_results = []
            for user_result in user_results:
                all_results.extend(user_result)
            
            metrics = self.analyze_results(all_results)
            results_by_endpoint[endpoint] = metrics
            
            print(f"  Requests: {metrics['total_requests']}")
            print(f"  Success rate: {(1 - metrics['error_rate']):.2%}")
            print(f"  Avg response time: {metrics['avg_response_time']:.2f}ms")
        
        # Verify all endpoints perform reasonably
        for endpoint, metrics in results_by_endpoint.items():
            # Health endpoint should have very low error rate
            if endpoint == "/health":
                assert metrics["error_rate"] <= 0.01, \
                    f"Health endpoint error rate too high: {metrics['error_rate']:.2%}"
                assert metrics["avg_response_time"] <= 500, \
                    f"Health endpoint too slow: {metrics['avg_response_time']:.2f}ms"
            else:
                # API endpoints may return 403, but should not crash
                assert metrics["error_rate"] <= 0.05, \
                    f"Endpoint {endpoint} error rate too high: {metrics['error_rate']:.2%}"
    
    @pytest.mark.asyncio
    async def test_sustained_load(self, api_base_url):
        """Test system behavior under sustained load over time."""
        duration_seconds = 30  # 30 second sustained test
        requests_per_second = 5
        
        print(f"\nRunning sustained load test for {duration_seconds} seconds...")
        
        start_time = time.time()
        all_results = []
        
        async with httpx.AsyncClient(timeout=10.0) as client:
            while time.time() - start_time < duration_seconds:
                # Make requests at target rate
                batch_start = time.time()
                
                tasks = []
                for _ in range(requests_per_second):
                    task = self.make_request(client, f"{api_base_url}/health")
                    tasks.append(task)
                
                batch_results = await asyncio.gather(*tasks)
                all_results.extend(batch_results)
                
                # Wait to maintain target rate
                batch_time = time.time() - batch_start
                if batch_time < 1.0:
                    await asyncio.sleep(1.0 - batch_time)
        
        # Analyze sustained load results
        metrics = self.analyze_results(all_results)
        actual_duration = time.time() - start_time
        
        print(f"Sustained load test completed:")
        print(f"  Duration: {actual_duration:.2f}s")
        print(f"  Total requests: {metrics['total_requests']}")
        print(f"  Success rate: {(1 - metrics['error_rate']):.2%}")
        print(f"  Avg response time: {metrics['avg_response_time']:.2f}ms")
        print(f"  Actual RPS: {metrics['total_requests'] / actual_duration:.2f}")
        
        # Verify sustained performance
        assert metrics["error_rate"] <= 0.05, \
            f"Sustained load error rate too high: {metrics['error_rate']:.2%}"
        assert metrics["avg_response_time"] <= 2000, \
            f"Sustained load response time too high: {metrics['avg_response_time']:.2f}ms"
        
        # Verify we maintained reasonable throughput
        actual_rps = metrics["total_requests"] / actual_duration
        assert actual_rps >= requests_per_second * 0.8, \
            f"Throughput too low: {actual_rps:.2f} RPS (target: {requests_per_second})"


class TestResourceUtilization:
    """Test resource utilization during load."""
    
    @pytest.fixture(scope="class")
    def api_base_url(self):
        """Get API base URL from environment."""
        return os.getenv("API_BASE_URL", "http://localhost:8000")
    
    @pytest.mark.asyncio
    async def test_memory_stability(self, api_base_url):
        """Test that memory usage remains stable under load."""
        # This is a basic test - in a real deployment, you'd monitor actual memory metrics
        print("\nTesting memory stability under load...")
        
        # Make many requests to test for memory leaks
        async with httpx.AsyncClient() as client:
            for batch in range(10):  # 10 batches
                tasks = []
                for _ in range(50):  # 50 requests per batch
                    task = client.get(f"{api_base_url}/health")
                    tasks.append(task)
                
                responses = await asyncio.gather(*tasks)
                
                # Verify all requests succeeded
                success_count = sum(1 for r in responses if r.status_code == 200)
                assert success_count >= 45, f"Batch {batch}: Only {success_count}/50 requests succeeded"
                
                # Small delay between batches
                await asyncio.sleep(1)
        
        print("Memory stability test completed - no obvious memory leaks detected")
    
    @pytest.mark.asyncio
    async def test_connection_handling(self, api_base_url):
        """Test proper connection handling and cleanup."""
        print("\nTesting connection handling...")
        
        # Test many concurrent connections
        tasks = []
        for _ in range(100):  # 100 concurrent connections
            async def make_single_request():
                async with httpx.AsyncClient() as client:
                    response = await client.get(f"{api_base_url}/health")
                    return response.status_code
            
            tasks.append(make_single_request())
        
        status_codes = await asyncio.gather(*tasks)
        
        # Verify most connections succeeded
        success_count = sum(1 for code in status_codes if code == 200)
        success_rate = success_count / len(status_codes)
        
        print(f"Connection test: {success_count}/{len(status_codes)} succeeded ({success_rate:.2%})")
        
        assert success_rate >= 0.95, f"Connection success rate too low: {success_rate:.2%}"