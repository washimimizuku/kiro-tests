#!/bin/bash

# ============================================================================
# Work Tracker Deployment Script
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
AWS_REGION="us-east-1"
SKIP_TESTS=false
SKIP_BUILD=false
SKIP_INFRA=false

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

Deploy Work Tracker application to AWS

OPTIONS:
    -e, --environment ENV    Target environment (staging|prod) [default: staging]
    -r, --region REGION      AWS region [default: us-east-1]
    --skip-tests            Skip running tests before deployment
    --skip-build            Skip building Docker images
    --skip-infra            Skip infrastructure deployment
    -h, --help              Show this help message

EXAMPLES:
    $0                                    # Deploy to staging
    $0 -e prod                           # Deploy to production
    $0 -e staging --skip-tests           # Deploy to staging without tests
    $0 --skip-infra                      # Deploy only application (skip infrastructure)

PREREQUISITES:
    - AWS CLI configured with appropriate credentials
    - Docker installed and running
    - Node.js and npm installed
    - Python and Poetry installed
    - Terraform installed

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-infra)
            SKIP_INFRA=true
            shift
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

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "prod" ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be 'staging' or 'prod'"
    exit 1
fi

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running"
        exit 1
    fi
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        exit 1
    fi
    
    # Check Poetry
    if ! command -v poetry &> /dev/null; then
        print_error "Poetry is not installed"
        exit 1
    fi
    
    # Check Terraform (only if not skipping infra)
    if [[ "$SKIP_INFRA" == false ]] && ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Run tests
run_tests() {
    if [[ "$SKIP_TESTS" == true ]]; then
        print_warning "Skipping tests"
        return
    fi
    
    print_status "Running tests..."
    
    # Backend tests
    print_status "Running backend tests..."
    cd backend
    poetry install --no-interaction
    poetry run pytest tests/ -v
    cd ..
    
    # Frontend tests
    print_status "Running frontend tests..."
    cd frontend
    npm ci
    npm run test:ci
    cd ..
    
    print_success "All tests passed"
}

# Build and push Docker images
build_and_push_images() {
    if [[ "$SKIP_BUILD" == true ]]; then
        print_warning "Skipping image build"
        return
    fi
    
    print_status "Building and pushing Docker images..."
    
    # Login to ECR
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
    
    # Build backend image
    print_status "Building backend image..."
    cd backend
    
    ECR_REGISTRY=$(aws sts get-caller-identity --query Account --output text).dkr.ecr.$AWS_REGION.amazonaws.com
    ECR_REPOSITORY="work-tracker-backend"
    IMAGE_TAG="$ENVIRONMENT-$(git rev-parse --short HEAD)-$(date +%s)"
    
    docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
    docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
    
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
    docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest
    
    cd ..
    
    # Store image URI for later use
    export BACKEND_IMAGE_URI="$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
    
    print_success "Images built and pushed successfully"
    print_status "Backend image: $BACKEND_IMAGE_URI"
}

# Deploy infrastructure
deploy_infrastructure() {
    if [[ "$SKIP_INFRA" == true ]]; then
        print_warning "Skipping infrastructure deployment"
        return
    fi
    
    print_status "Deploying infrastructure..."
    
    cd infrastructure/terraform
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    print_status "Planning infrastructure changes..."
    terraform plan -var-file="$ENVIRONMENT.tfvars" -var="backend_image=$BACKEND_IMAGE_URI" -out=tfplan
    
    # Apply changes
    print_status "Applying infrastructure changes..."
    terraform apply -auto-approve tfplan
    
    cd ../..
    
    print_success "Infrastructure deployed successfully"
}

# Build and deploy frontend
deploy_frontend() {
    print_status "Building and deploying frontend..."
    
    cd frontend
    
    # Install dependencies
    npm ci
    
    # Get environment-specific configuration
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        API_URL=$(aws ssm get-parameter --name "/work-tracker/prod/api-url" --query "Parameter.Value" --output text 2>/dev/null || echo "https://api.worktracker.example.com")
        COGNITO_USER_POOL_ID=$(aws ssm get-parameter --name "/work-tracker/prod/cognito-user-pool-id" --query "Parameter.Value" --output text 2>/dev/null || echo "")
        COGNITO_CLIENT_ID=$(aws ssm get-parameter --name "/work-tracker/prod/cognito-client-id" --query "Parameter.Value" --output text 2>/dev/null || echo "")
        S3_BUCKET=$(aws ssm get-parameter --name "/work-tracker/prod/s3-bucket" --query "Parameter.Value" --output text 2>/dev/null || echo "")
        CLOUDFRONT_DISTRIBUTION_ID=$(aws ssm get-parameter --name "/work-tracker/prod/cloudfront-distribution-id" --query "Parameter.Value" --output text 2>/dev/null || echo "")
    else
        API_URL=$(aws ssm get-parameter --name "/work-tracker/staging/api-url" --query "Parameter.Value" --output text 2>/dev/null || echo "https://staging-api.worktracker.example.com")
        COGNITO_USER_POOL_ID=$(aws ssm get-parameter --name "/work-tracker/staging/cognito-user-pool-id" --query "Parameter.Value" --output text 2>/dev/null || echo "")
        COGNITO_CLIENT_ID=$(aws ssm get-parameter --name "/work-tracker/staging/cognito-client-id" --query "Parameter.Value" --output text 2>/dev/null || echo "")
        S3_BUCKET=$(aws ssm get-parameter --name "/work-tracker/staging/s3-bucket" --query "Parameter.Value" --output text 2>/dev/null || echo "")
        CLOUDFRONT_DISTRIBUTION_ID=$(aws ssm get-parameter --name "/work-tracker/staging/cloudfront-distribution-id" --query "Parameter.Value" --output text 2>/dev/null || echo "")
    fi
    
    # Build frontend with environment variables
    REACT_APP_API_URL="$API_URL" \
    REACT_APP_COGNITO_USER_POOL_ID="$COGNITO_USER_POOL_ID" \
    REACT_APP_COGNITO_CLIENT_ID="$COGNITO_CLIENT_ID" \
    REACT_APP_AWS_REGION="$AWS_REGION" \
    REACT_APP_ENVIRONMENT="$ENVIRONMENT" \
    npm run build
    
    # Deploy to S3
    if [[ -n "$S3_BUCKET" ]]; then
        print_status "Deploying to S3 bucket: $S3_BUCKET"
        aws s3 sync dist/ s3://$S3_BUCKET --delete --cache-control "public, max-age=31536000, immutable" --exclude "*.html"
        aws s3 sync dist/ s3://$S3_BUCKET --delete --cache-control "public, max-age=0, must-revalidate" --include "*.html"
        
        # Invalidate CloudFront
        if [[ -n "$CLOUDFRONT_DISTRIBUTION_ID" ]]; then
            print_status "Invalidating CloudFront distribution: $CLOUDFRONT_DISTRIBUTION_ID"
            aws cloudfront create-invalidation --distribution-id $CLOUDFRONT_DISTRIBUTION_ID --paths "/*"
        fi
    else
        print_warning "S3 bucket not configured, skipping frontend deployment"
    fi
    
    cd ..
    
    print_success "Frontend deployed successfully"
}

# Deploy backend service
deploy_backend() {
    print_status "Deploying backend service..."
    
    CLUSTER_NAME="work-tracker-$ENVIRONMENT-cluster"
    SERVICE_NAME="work-tracker-$ENVIRONMENT-backend"
    
    # Get current task definition
    TASK_DEFINITION=$(aws ecs describe-task-definition \
        --task-definition $SERVICE_NAME \
        --query 'taskDefinition' \
        --output json)
    
    # Update image URI in task definition
    NEW_TASK_DEFINITION=$(echo $TASK_DEFINITION | jq --arg IMAGE_URI "$BACKEND_IMAGE_URI" \
        '.containerDefinitions[0].image = $IMAGE_URI | 
         del(.taskDefinitionArn) | 
         del(.revision) | 
         del(.status) | 
         del(.requiresAttributes) | 
         del(.placementConstraints) | 
         del(.compatibilities) | 
         del(.registeredAt) | 
         del(.registeredBy)')
    
    # Register new task definition
    NEW_TASK_DEF_ARN=$(echo $NEW_TASK_DEFINITION | aws ecs register-task-definition \
        --cli-input-json file:///dev/stdin \
        --query 'taskDefinition.taskDefinitionArn' \
        --output text)
    
    # Update service with new task definition
    aws ecs update-service \
        --cluster $CLUSTER_NAME \
        --service $SERVICE_NAME \
        --task-definition $NEW_TASK_DEF_ARN
    
    # Wait for deployment to complete
    print_status "Waiting for deployment to complete..."
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME
    
    print_success "Backend service deployed successfully"
}

# Run post-deployment tests
run_post_deployment_tests() {
    print_status "Running post-deployment tests..."
    
    # Get API URL
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        API_URL=$(aws ssm get-parameter --name "/work-tracker/prod/api-url" --query "Parameter.Value" --output text 2>/dev/null || echo "https://api.worktracker.example.com")
    else
        API_URL=$(aws ssm get-parameter --name "/work-tracker/staging/api-url" --query "Parameter.Value" --output text 2>/dev/null || echo "https://staging-api.worktracker.example.com")
    fi
    
    # Health check
    print_status "Checking API health at $API_URL"
    
    for i in {1..30}; do
        if curl -f "$API_URL/health" > /dev/null 2>&1; then
            print_success "API is healthy!"
            break
        fi
        print_status "Waiting for API to be ready... (attempt $i/30)"
        sleep 10
    done
    
    # Final health check
    if ! curl -f "$API_URL/health"; then
        print_error "API health check failed!"
        exit 1
    fi
    
    print_success "Post-deployment tests passed"
}

# Main deployment function
main() {
    print_status "Starting deployment to $ENVIRONMENT environment"
    print_status "AWS Region: $AWS_REGION"
    
    check_prerequisites
    run_tests
    build_and_push_images
    deploy_infrastructure
    deploy_frontend
    deploy_backend
    run_post_deployment_tests
    
    print_success "🎉 Deployment to $ENVIRONMENT completed successfully!"
    
    if [[ "$ENVIRONMENT" == "prod" ]]; then
        print_status "Production URL: https://worktracker.example.com"
    else
        print_status "Staging URL: Check CloudFront distribution domain"
    fi
}

# Run main function
main