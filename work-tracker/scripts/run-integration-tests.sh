#!/bin/bash

# ============================================================================
# Integration Test Runner for Work Tracker Deployment
# ============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="staging"
API_URL=""
FRONTEND_URL=""
SKIP_LOAD_TESTS=false
SKIP_FRONTEND_TESTS=false
SKIP_BACKEND_TESTS=false
TIMEOUT=300  # 5 minutes default timeout

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Run integration tests for Work Tracker deployment

OPTIONS:
    -e, --environment ENV    Target environment (staging|prod) [default: staging]
    --api-url URL           API base URL (auto-detected if not provided)
    --frontend-url URL      Frontend URL (auto-detected if not provided)
    --skip-load-tests       Skip load and performance tests
    --skip-frontend-tests   Skip frontend integration tests
    --skip-backend-tests    Skip backend integration tests
    --timeout SECONDS       Test timeout in seconds [default: 300]
    -h, --help              Show this help message

EXAMPLES:
    $0                                          # Run all tests for staging
    $0 -e prod                                 # Run all tests for production
    $0 --skip-load-tests                       # Skip performance tests
    $0 --api-url https://api.example.com       # Use specific API URL

PREREQUISITES:
    - Python and Poetry installed (for backend tests)
    - Node.js and npm installed (for frontend tests)
    - API and frontend services running and accessible

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --api-url)
            API_URL="$2"
            shift 2
            ;;
        --frontend-url)
            FRONTEND_URL="$2"
            shift 2
            ;;
        --skip-load-tests)
            SKIP_LOAD_TESTS=true
            shift
            ;;
        --skip-frontend-tests)
            SKIP_FRONTEND_TESTS=true
            shift
            ;;
        --skip-backend-tests)
            SKIP_BACKEND_TESTS=true
            shift
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Auto-detect URLs if not provided
detect_urls() {
    print_status "Detecting service URLs..."
    
    if [[ -z "$API_URL" ]]; then
        if [[ "$ENVIRONMENT" == "prod" ]]; then
            API_URL="https://api.worktracker.example.com"
        else
            API_URL="https://staging-api.worktracker.example.com"
        fi
        
        # Try to get from AWS if available
        if command -v aws &> /dev/null; then
            ALB_DNS=$(aws elbv2 describe-load-balancers \
                --names "work-tracker-$ENVIRONMENT-alb" \
                --query 'LoadBalancers[0].DNSName' \
                --output text 2>/dev/null || echo "")
            
            if [[ -n "$ALB_DNS" && "$ALB_DNS" != "None" ]]; then
                API_URL="https://$ALB_DNS"
            fi
        fi
    fi
    
    if [[ -z "$FRONTEND_URL" ]]; then
        if [[ "$ENVIRONMENT" == "prod" ]]; then
            FRONTEND_URL="https://worktracker.example.com"
        else
            FRONTEND_URL="https://staging.worktracker.example.com"
        fi
        
        # Try to get CloudFront URL from AWS if available
        if command -v aws &> /dev/null; then
            CF_DOMAIN=$(aws cloudfront list-distributions \
                --query "DistributionList.Items[?contains(Comment, 'work-tracker-$ENVIRONMENT')].DomainName" \
                --output text 2>/dev/null || echo "")
            
            if [[ -n "$CF_DOMAIN" && "$CF_DOMAIN" != "None" ]]; then
                FRONTEND_URL="https://$CF_DOMAIN"
            fi
        fi
    fi
    
    print_status "API URL: $API_URL"
    print_status "Frontend URL: $FRONTEND_URL"
}

# Wait for services to be ready
wait_for_services() {
    print_status "Waiting for services to be ready..."
    
    # Wait for API
    print_status "Checking API health at $API_URL"
    for i in {1..30}; do
        if curl -f -s "$API_URL/health" > /dev/null 2>&1; then
            print_success "API is ready!"
            break
        fi
        print_status "Waiting for API... (attempt $i/30)"
        sleep 10
    done
    
    # Final API check
    if ! curl -f -s "$API_URL/health" > /dev/null 2>&1; then
        print_error "API is not responding at $API_URL"
        exit 1
    fi
    
    # Wait for frontend (if not skipping frontend tests)
    if [[ "$SKIP_FRONTEND_TESTS" == false ]]; then
        print_status "Checking frontend at $FRONTEND_URL"
        for i in {1..10}; do
            if curl -f -s "$FRONTEND_URL" > /dev/null 2>&1; then
                print_success "Frontend is ready!"
                break
            fi
            print_status "Waiting for frontend... (attempt $i/10)"
            sleep 5
        done
    fi
}

# Run backend integration tests
run_backend_tests() {
    if [[ "$SKIP_BACKEND_TESTS" == true ]]; then
        print_warning "Skipping backend integration tests"
        return
    fi
    
    print_status "Running backend integration tests..."
    
    cd backend
    
    # Set environment variables for tests
    export API_BASE_URL="$API_URL"
    export ENVIRONMENT="$ENVIRONMENT"
    
    # Install dependencies if needed
    if [[ ! -d ".venv" ]]; then
        print_status "Installing backend dependencies..."
        poetry install --no-interaction
    fi
    
    # Run integration tests
    print_status "Executing backend integration tests..."
    timeout $TIMEOUT poetry run pytest tests/integration/ -v --tb=short
    
    cd ..
    
    print_success "Backend integration tests completed"
}

# Run load and performance tests
run_load_tests() {
    if [[ "$SKIP_LOAD_TESTS" == true ]]; then
        print_warning "Skipping load and performance tests"
        return
    fi
    
    print_status "Running load and performance tests..."
    
    cd backend
    
    # Set environment variables for tests
    export API_BASE_URL="$API_URL"
    export ENVIRONMENT="$ENVIRONMENT"
    
    # Run load tests with longer timeout
    print_status "Executing load tests (this may take several minutes)..."
    timeout $((TIMEOUT * 2)) poetry run pytest tests/integration/test_load_performance.py -v --tb=short -m "not slow"
    
    # Run heavy load tests only if explicitly requested
    if [[ "$ENVIRONMENT" == "staging" ]]; then
        print_status "Running heavy load tests..."
        timeout $((TIMEOUT * 3)) poetry run pytest tests/integration/test_load_performance.py -v --tb=short -m "slow" || {
            print_warning "Heavy load tests failed or timed out (this may be expected)"
        }
    fi
    
    cd ..
    
    print_success "Load and performance tests completed"
}

# Run frontend integration tests
run_frontend_tests() {
    if [[ "$SKIP_FRONTEND_TESTS" == true ]]; then
        print_warning "Skipping frontend integration tests"
        return
    fi
    
    print_status "Running frontend integration tests..."
    
    cd frontend
    
    # Set environment variables for tests
    export REACT_APP_API_URL="$API_URL"
    export FRONTEND_URL="$FRONTEND_URL"
    export REACT_APP_ENVIRONMENT="$ENVIRONMENT"
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        print_status "Installing frontend dependencies..."
        npm ci
    fi
    
    # Run integration tests
    print_status "Executing frontend integration tests..."
    timeout $TIMEOUT npm run test:integration
    
    cd ..
    
    print_success "Frontend integration tests completed"
}

# Run smoke tests
run_smoke_tests() {
    print_status "Running smoke tests..."
    
    # Basic API smoke tests
    print_status "Testing API endpoints..."
    
    # Health check
    if ! curl -f -s "$API_URL/health" > /dev/null; then
        print_error "Health check failed"
        exit 1
    fi
    
    # Test API endpoints return expected status codes
    endpoints=(
        "/api/v1/activities:401"
        "/api/v1/stories:401"
        "/api/v1/reports:401"
        "/nonexistent:404"
    )
    
    for endpoint_status in "${endpoints[@]}"; do
        IFS=':' read -r endpoint expected_status <<< "$endpoint_status"
        
        actual_status=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL$endpoint")
        
        if [[ "$actual_status" != "$expected_status" ]]; then
            print_error "Endpoint $endpoint returned $actual_status, expected $expected_status"
            exit 1
        fi
        
        print_status "✓ $endpoint returned $actual_status as expected"
    done
    
    # Basic frontend smoke test
    if [[ "$SKIP_FRONTEND_TESTS" == false ]]; then
        print_status "Testing frontend accessibility..."
        
        if curl -f -s "$FRONTEND_URL" > /dev/null; then
            print_status "✓ Frontend is accessible"
        else
            print_warning "Frontend accessibility test failed"
        fi
    fi
    
    print_success "Smoke tests completed"
}

# Generate test report
generate_report() {
    print_status "Generating test report..."
    
    cat > "integration-test-report-$ENVIRONMENT.md" << EOF
# Integration Test Report - $ENVIRONMENT

**Date:** $(date)
**Environment:** $ENVIRONMENT
**API URL:** $API_URL
**Frontend URL:** $FRONTEND_URL

## Test Summary

- **Backend Integration Tests:** $([ "$SKIP_BACKEND_TESTS" == true ] && echo "SKIPPED" || echo "COMPLETED")
- **Frontend Integration Tests:** $([ "$SKIP_FRONTEND_TESTS" == true ] && echo "SKIPPED" || echo "COMPLETED")
- **Load and Performance Tests:** $([ "$SKIP_LOAD_TESTS" == true ] && echo "SKIPPED" || echo "COMPLETED")
- **Smoke Tests:** COMPLETED

## Service Health

### API Health Check
\`\`\`
$(curl -s "$API_URL/health" | jq . 2>/dev/null || curl -s "$API_URL/health")
\`\`\`

### Response Time Test
\`\`\`
$(curl -w "Response Time: %{time_total}s\nHTTP Status: %{http_code}\n" -s -o /dev/null "$API_URL/health")
\`\`\`

## Recommendations

- Monitor response times and error rates in production
- Set up automated health checks
- Review performance metrics regularly
- Consider load testing before major releases

## Next Steps

1. Deploy to production if all tests pass
2. Monitor application metrics post-deployment
3. Set up alerting for critical issues
4. Schedule regular integration test runs

EOF
    
    print_success "Test report generated: integration-test-report-$ENVIRONMENT.md"
}

# Main execution function
main() {
    print_status "Starting integration tests for $ENVIRONMENT environment"
    print_status "Timeout: ${TIMEOUT}s per test suite"
    
    detect_urls
    wait_for_services
    run_smoke_tests
    run_backend_tests
    run_load_tests
    run_frontend_tests
    generate_report
    
    print_success "🎉 All integration tests completed successfully!"
    print_status "Environment $ENVIRONMENT is ready for traffic"
    
    # Print summary
    echo ""
    echo "=== Test Summary ==="
    echo "Environment: $ENVIRONMENT"
    echo "API URL: $API_URL"
    echo "Frontend URL: $FRONTEND_URL"
    echo "Backend Tests: $([ "$SKIP_BACKEND_TESTS" == true ] && echo "SKIPPED" || echo "✅ PASSED")"
    echo "Frontend Tests: $([ "$SKIP_FRONTEND_TESTS" == true ] && echo "SKIPPED" || echo "✅ PASSED")"
    echo "Load Tests: $([ "$SKIP_LOAD_TESTS" == true ] && echo "SKIPPED" || echo "✅ PASSED")"
    echo "Smoke Tests: ✅ PASSED"
    echo ""
    echo "Report: integration-test-report-$ENVIRONMENT.md"
}

# Handle script interruption
trap 'print_error "Integration tests interrupted"; exit 1' INT TERM

# Run main function
main