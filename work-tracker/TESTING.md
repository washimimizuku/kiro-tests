# Work Tracker Testing Guide

This guide covers all testing strategies and procedures for the Work Tracker application, including unit tests, integration tests, property-based tests, and deployment validation.

## Table of Contents

1. [Testing Strategy](#testing-strategy)
2. [Test Types](#test-types)
3. [Running Tests](#running-tests)
4. [Integration Testing](#integration-testing)
5. [Performance Testing](#performance-testing)
6. [Deployment Validation](#deployment-validation)
7. [Continuous Integration](#continuous-integration)

## Testing Strategy

Work Tracker employs a comprehensive testing strategy with multiple layers:

### Test Pyramid

```
    /\
   /  \     E2E Tests (Few)
  /____\    
 /      \   Integration Tests (Some)
/________\  Unit Tests (Many)
```

- **Unit Tests**: Fast, isolated tests for individual components
- **Integration Tests**: Test component interactions and external services
- **End-to-End Tests**: Full user workflow validation
- **Property-Based Tests**: Validate universal properties across inputs

### Testing Principles

1. **Fast Feedback**: Unit tests run quickly for immediate feedback
2. **Comprehensive Coverage**: All critical paths are tested
3. **Realistic Testing**: Integration tests use real services when possible
4. **Property Validation**: Universal properties are verified with randomized inputs
5. **Performance Baseline**: Response times and throughput are validated

## Test Types

### Unit Tests

**Backend Unit Tests** (`backend/tests/`)
- Model validation and business logic
- Service layer functionality
- Utility functions and helpers
- Authentication and authorization logic

**Frontend Unit Tests** (`frontend/src/test/`)
- Component rendering and behavior
- Hook functionality
- Utility functions
- State management

### Property-Based Tests

**Backend Properties** (`backend/tests/test_*_properties.py`)
- Activity lifecycle consistency
- Story enhancement validation
- Authentication token handling
- Data export completeness

**Frontend Properties** (`frontend/src/test/*.properties.test.ts`)
- UI component behavior across inputs
- Data synchronization properties
- Offline functionality validation

### Integration Tests

**Backend Integration** (`backend/tests/integration/`)
- Database connectivity and operations
- Redis cache functionality
- API endpoint integration
- External service communication

**Frontend Integration** (`frontend/src/test/integration/`)
- API connectivity from frontend
- Authentication flow validation
- Cross-browser compatibility
- Performance baseline validation

### Load and Performance Tests

**Load Testing** (`backend/tests/integration/test_load_performance.py`)
- Concurrent user simulation
- Response time measurement
- Throughput validation
- Resource utilization monitoring

## Running Tests

### Prerequisites

**Backend Testing:**
```bash
cd backend
poetry install
```

**Frontend Testing:**
```bash
cd frontend
npm ci
```

**Integration Testing:**
```bash
# Docker and Docker Compose
docker --version
docker-compose --version
```

### Unit Tests

**Backend Unit Tests:**
```bash
cd backend
poetry run pytest tests/ -v --cov=app
```

**Frontend Unit Tests:**
```bash
cd frontend
npm run test
npm run test:coverage  # With coverage report
```

### Property-Based Tests

**Backend Properties:**
```bash
cd backend
poetry run python run_property_test.py
poetry run python run_auth_property_test.py
poetry run python run_story_property_test.py
```

**Frontend Properties:**
```bash
cd frontend
npm run test:properties
```

### Integration Tests

**Using Docker Compose (Recommended):**
```bash
# Start test environment
docker-compose -f docker-compose.test.yml up -d

# Run integration tests
docker-compose -f docker-compose.test.yml run integration-tests

# Clean up
docker-compose -f docker-compose.test.yml down -v
```

**Manual Integration Testing:**
```bash
# Start services
docker-compose up -d postgres redis

# Run backend integration tests
cd backend
export API_BASE_URL=http://localhost:8000
poetry run pytest tests/integration/ -v

# Run frontend integration tests
cd frontend
export REACT_APP_API_URL=http://localhost:8000
npm run test:integration
```

**Full Integration Test Suite:**
```bash
# Run comprehensive integration tests
./scripts/run-integration-tests.sh

# Run for specific environment
./scripts/run-integration-tests.sh -e staging

# Skip load tests for faster execution
./scripts/run-integration-tests.sh --skip-load-tests
```

### Load and Performance Tests

**Light Load Testing:**
```bash
cd backend
export API_BASE_URL=http://localhost:8000
poetry run pytest tests/integration/test_load_performance.py::TestLoadPerformance::test_light_load_performance -v
```

**Full Load Testing:**
```bash
cd backend
export API_BASE_URL=http://localhost:8000
poetry run pytest tests/integration/test_load_performance.py -v
```

**Heavy Load Testing:**
```bash
cd backend
export API_BASE_URL=http://localhost:8000
poetry run pytest tests/integration/test_load_performance.py -v -m slow
```

## Integration Testing

### Test Environment Setup

Integration tests require a complete environment with:

- PostgreSQL database
- Redis cache
- Backend API service
- Frontend application (for full integration)

### Environment Variables

**Required for Backend Integration Tests:**
```bash
export API_BASE_URL=http://localhost:8000
export DATABASE_URL=postgresql://test_user:test_password@localhost:5432/test_db
export REDIS_URL=redis://localhost:6379
export AWS_REGION=us-east-1
export ENVIRONMENT=test
```

**Required for Frontend Integration Tests:**
```bash
export REACT_APP_API_URL=http://localhost:8000
export FRONTEND_URL=http://localhost:3000
export REACT_APP_ENVIRONMENT=test
```

### Test Categories

**Health and Connectivity Tests:**
- API health endpoint validation
- Database connectivity verification
- Redis cache functionality
- Service dependency checks

**API Integration Tests:**
- Authentication flow validation
- CORS configuration verification
- Error handling across service boundaries
- Rate limiting and security measures

**Performance Baseline Tests:**
- Response time validation
- Throughput measurement
- Concurrent request handling
- Resource utilization monitoring

### Test Data Management

**Database Test Data:**
- Tests use isolated test database
- Automatic cleanup after test runs
- Fixtures for consistent test data
- Migration validation

**Cache Test Data:**
- Redis test instance with separate keyspace
- Automatic key expiration for cleanup
- Cache consistency validation

## Performance Testing

### Performance Metrics

**Response Time Targets:**
- Health endpoint: < 500ms
- API endpoints: < 2000ms
- Database queries: < 1000ms

**Throughput Targets:**
- Light load: 10+ requests/second
- Medium load: 20+ requests/second
- Sustained load: 5+ requests/second over 30 seconds

**Error Rate Targets:**
- Light/Medium load: < 5% error rate
- Heavy load: < 10% error rate
- Sustained load: < 5% error rate

### Load Test Scenarios

**Light Load (5 users, 10 requests each):**
- Validates basic performance
- Quick feedback for development
- Part of regular CI pipeline

**Medium Load (10 users, 20 requests each):**
- Validates typical usage patterns
- Identifies performance bottlenecks
- Run before major releases

**Heavy Load (20 users, 30 requests each):**
- Stress testing for peak usage
- Identifies breaking points
- Run before production deployment

**Sustained Load (5 RPS for 30 seconds):**
- Tests system stability over time
- Identifies memory leaks
- Validates auto-scaling behavior

### Performance Monitoring

**Metrics Collected:**
- Response times (average, median, 95th percentile)
- Request success/failure rates
- Concurrent connection handling
- Resource utilization patterns

**Analysis and Reporting:**
- Automated performance reports
- Trend analysis over time
- Performance regression detection
- Capacity planning insights

## Deployment Validation

### Pre-Deployment Testing

**Staging Environment Validation:**
```bash
# Run full integration test suite
./scripts/run-integration-tests.sh -e staging

# Validate specific components
./scripts/run-integration-tests.sh -e staging --skip-load-tests
```

**Production Readiness Checks:**
- All integration tests pass
- Performance meets baseline requirements
- Security scans complete without critical issues
- Database migrations applied successfully

### Post-Deployment Testing

**Smoke Tests:**
```bash
# Quick validation after deployment
./scripts/run-integration-tests.sh -e prod --skip-load-tests --skip-frontend-tests
```

**Health Monitoring:**
- API health endpoint monitoring
- Database connectivity verification
- Cache functionality validation
- Error rate monitoring

### Rollback Testing

**Rollback Validation:**
- Previous version compatibility
- Database migration rollback capability
- Service restart resilience
- Data integrity preservation

## Continuous Integration

### GitHub Actions Integration

**CI Pipeline Tests:**
- Unit tests for all components
- Property-based test execution
- Integration test validation
- Security scanning
- Performance baseline validation

**Test Execution Strategy:**
- Parallel test execution for speed
- Fail-fast on critical test failures
- Comprehensive reporting
- Artifact preservation

### Test Reporting

**Coverage Reports:**
- Backend: pytest-cov with XML output
- Frontend: Vitest with LCOV output
- Combined coverage reporting
- Coverage trend tracking

**Performance Reports:**
- Response time measurements
- Throughput analysis
- Resource utilization metrics
- Performance regression alerts

### Quality Gates

**Merge Requirements:**
- All unit tests pass
- Property-based tests pass
- Integration tests pass (staging)
- Code coverage > 80%
- Security scans pass

**Deployment Requirements:**
- All tests pass in staging
- Performance baselines met
- Load tests complete successfully
- Manual approval for production

## Troubleshooting

### Common Test Issues

**Database Connection Issues:**
```bash
# Check database status
docker-compose ps postgres

# View database logs
docker-compose logs postgres

# Reset database
docker-compose down -v
docker-compose up -d postgres
```

**Redis Connection Issues:**
```bash
# Check Redis status
docker-compose ps redis

# Test Redis connectivity
redis-cli -h localhost -p 6379 ping
```

**API Connectivity Issues:**
```bash
# Check API health
curl -f http://localhost:8000/health

# View API logs
docker-compose logs api-gateway
```

### Test Environment Reset

**Complete Environment Reset:**
```bash
# Stop all services
docker-compose -f docker-compose.test.yml down -v

# Remove test data
docker volume prune -f

# Restart test environment
docker-compose -f docker-compose.test.yml up -d
```

**Database Reset Only:**
```bash
# Reset test database
docker-compose -f docker-compose.test.yml restart postgres-test
```

### Performance Test Debugging

**Slow Test Investigation:**
```bash
# Run with detailed timing
poetry run pytest tests/integration/test_load_performance.py -v -s

# Profile test execution
poetry run pytest tests/integration/ --profile
```

**Load Test Analysis:**
```bash
# Run single user simulation
poetry run pytest tests/integration/test_load_performance.py::TestLoadPerformance::test_light_load_performance -v -s
```

## Best Practices

### Test Writing Guidelines

1. **Test Naming**: Use descriptive names that explain what is being tested
2. **Test Independence**: Each test should be independent and idempotent
3. **Test Data**: Use factories or fixtures for consistent test data
4. **Assertions**: Make specific assertions about expected behavior
5. **Error Testing**: Test both success and failure scenarios

### Performance Testing Guidelines

1. **Baseline Establishment**: Establish performance baselines early
2. **Realistic Load**: Use realistic user behavior patterns
3. **Environment Consistency**: Use consistent test environments
4. **Metric Collection**: Collect comprehensive performance metrics
5. **Trend Analysis**: Track performance trends over time

### Integration Testing Guidelines

1. **Service Dependencies**: Test with real services when possible
2. **Error Scenarios**: Test error handling and recovery
3. **Data Consistency**: Validate data consistency across services
4. **Security Testing**: Include security validation in integration tests
5. **Environment Parity**: Keep test environments close to production

For additional testing support, refer to the CI/CD documentation or contact the development team.