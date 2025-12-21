# Work Tracker Deployment Guide

This guide covers the complete deployment process for the Work Tracker application, including infrastructure setup, CI/CD pipeline configuration, and monitoring.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Infrastructure Deployment](#infrastructure-deployment)
4. [CI/CD Pipeline Setup](#cicd-pipeline-setup)
5. [Manual Deployment](#manual-deployment)
6. [Monitoring Setup](#monitoring-setup)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

- **AWS CLI** v2.x configured with appropriate credentials
- **Terraform** >= 1.0
- **Docker** and Docker Compose
- **Node.js** >= 18.x and npm
- **Python** >= 3.11 and Poetry
- **Git** for version control

### AWS Permissions

Your AWS credentials need the following permissions:
- EC2, VPC, and networking resources
- RDS and ElastiCache management
- ECS Fargate cluster and service management
- S3 bucket creation and management
- CloudFront distribution management
- IAM role and policy management
- CloudWatch logs and metrics
- Secrets Manager access
- Cognito User Pool management

### Domain and SSL (Optional but Recommended)

- Domain name registered and managed in Route 53
- ACM certificate for HTTPS (must be in us-east-1 for CloudFront)

## Initial Setup

### 1. Clone and Configure

```bash
git clone <repository-url>
cd work-tracker
```

### 2. Configure Environment Variables

Copy and customize the Terraform variables:

```bash
cd infrastructure/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your specific values
```

### 3. Create ECR Repository

```bash
aws ecr create-repository --repository-name work-tracker-backend --region us-east-1
```

## Infrastructure Deployment

### Automated Deployment (Recommended)

Use the deployment script for a complete automated deployment:

```bash
# Deploy to staging
./scripts/deploy.sh

# Deploy to production
./scripts/deploy.sh -e prod

# Deploy without tests (faster)
./scripts/deploy.sh --skip-tests

# Deploy only application (skip infrastructure)
./scripts/deploy.sh --skip-infra
```

### Manual Infrastructure Deployment

If you prefer manual control:

```bash
cd infrastructure/terraform

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var-file="staging.tfvars"

# Apply infrastructure
terraform apply -var-file="staging.tfvars"
```

### Infrastructure Components

The Terraform deployment creates:

- **VPC** with public, private, database, and cache subnets
- **RDS PostgreSQL** with Multi-AZ deployment
- **ElastiCache Redis** for caching
- **ECS Fargate** cluster and services
- **Application Load Balancer** for traffic distribution
- **S3 + CloudFront** for frontend hosting
- **AWS Cognito** for authentication
- **CloudWatch** monitoring and alerting
- **IAM roles** and security policies

## CI/CD Pipeline Setup

### GitHub Actions Configuration

The repository includes two main workflows:

1. **Continuous Integration** (`.github/workflows/ci.yml`)
   - Runs on every push and pull request
   - Backend and frontend testing
   - Security scanning
   - Infrastructure validation

2. **Continuous Deployment** (`.github/workflows/cd.yml`)
   - Runs on main branch pushes
   - Builds and pushes Docker images
   - Deploys to staging automatically
   - Manual deployment to production

### Required GitHub Secrets

Configure these secrets in your GitHub repository:

```bash
# AWS Credentials
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY

# Staging Environment
STAGING_API_URL
STAGING_S3_BUCKET
STAGING_CLOUDFRONT_DISTRIBUTION_ID
STAGING_COGNITO_USER_POOL_ID
STAGING_COGNITO_CLIENT_ID

# Production Environment
PROD_API_URL
PROD_S3_BUCKET
PROD_CLOUDFRONT_DISTRIBUTION_ID
PROD_COGNITO_USER_POOL_ID
PROD_COGNITO_CLIENT_ID

# Optional: Slack notifications
SLACK_WEBHOOK_URL
```

### Setting Up Secrets

After infrastructure deployment, get the values from Terraform outputs:

```bash
cd infrastructure/terraform

# Get outputs
terraform output

# Set GitHub secrets using GitHub CLI
gh secret set STAGING_S3_BUCKET --body "$(terraform output -raw s3_bucket_name)"
gh secret set STAGING_CLOUDFRONT_DISTRIBUTION_ID --body "$(terraform output -raw cloudfront_distribution_id)"
# ... repeat for other secrets
```

## Manual Deployment

### Backend Deployment

```bash
# Build and push Docker image
cd backend
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
docker build -t work-tracker-backend .
docker tag work-tracker-backend:latest <account-id>.dkr.ecr.us-east-1.amazonaws.com/work-tracker-backend:latest
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/work-tracker-backend:latest

# Update ECS service
aws ecs update-service \
  --cluster work-tracker-staging-cluster \
  --service work-tracker-staging-backend \
  --force-new-deployment
```

### Frontend Deployment

```bash
# Build frontend
cd frontend
npm ci
npm run build

# Deploy to S3
aws s3 sync dist/ s3://your-s3-bucket --delete

# Invalidate CloudFront
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

## Monitoring Setup

### Automated Monitoring Setup

Use the monitoring setup script:

```bash
# Setup monitoring for staging
./scripts/setup-monitoring.sh --email admin@example.com

# Setup monitoring for production
./scripts/setup-monitoring.sh -e prod --email alerts@example.com
```

### Manual Monitoring Configuration

The monitoring setup includes:

- **CloudWatch Alarms** for infrastructure and application metrics
- **Custom Metrics** for application performance
- **Log Insights Queries** for troubleshooting
- **Custom Dashboard** for operational visibility
- **SNS Notifications** for alerts

### Key Metrics to Monitor

- **Application Performance**: Response time, error rate
- **Infrastructure Health**: CPU, memory, disk usage
- **Database Performance**: Query time, connections
- **User Activity**: Activities created, API usage

## Environment-Specific Configurations

### Staging Environment

- **Purpose**: Testing and validation
- **Resources**: Smaller instance sizes for cost optimization
- **Availability**: Single AZ deployment
- **Monitoring**: Basic alerting
- **Domain**: Uses CloudFront domain

### Production Environment

- **Purpose**: Live user traffic
- **Resources**: Production-sized instances
- **Availability**: Multi-AZ deployment with auto-scaling
- **Monitoring**: Comprehensive alerting and monitoring
- **Domain**: Custom domain with SSL certificate

## Deployment Strategies

### Blue-Green Deployment

For zero-downtime deployments:

1. Deploy new version to staging
2. Run comprehensive tests
3. Switch traffic to new version
4. Monitor for issues
5. Rollback if needed

### Rolling Deployment

ECS services use rolling deployments by default:

1. New tasks are started
2. Health checks verify new tasks
3. Old tasks are stopped
4. Process repeats until all tasks updated

### Rollback Procedures

#### Application Rollback

```bash
# Rollback to previous task definition
aws ecs update-service \
  --cluster work-tracker-prod-cluster \
  --service work-tracker-prod-backend \
  --task-definition work-tracker-prod-backend:PREVIOUS_REVISION
```

#### Infrastructure Rollback

```bash
cd infrastructure/terraform

# Revert to previous Terraform state
terraform apply -var-file="prod.tfvars" -target=module.ecs
```

## Security Considerations

### Network Security

- Private subnets for backend services
- Security groups with least-privilege access
- VPC endpoints for AWS services

### Data Security

- Encryption at rest for RDS and ElastiCache
- Encryption in transit for all communications
- Secrets stored in AWS Secrets Manager

### Access Control

- IAM roles with minimal required permissions
- Cognito for user authentication
- CloudFront with Origin Access Control

## Cost Optimization

### Development/Staging

- Use smaller instance types
- Single AZ deployments
- Shorter backup retention periods
- Scheduled scaling (stop non-prod resources overnight)

### Production

- Right-size instances based on usage
- Use Reserved Instances for predictable workloads
- Enable S3 lifecycle policies
- Monitor and optimize data transfer costs

## Troubleshooting

### Common Issues

#### ECS Service Won't Start

1. Check CloudWatch logs for container errors
2. Verify environment variables and secrets
3. Ensure security groups allow required traffic
4. Check task definition resource limits

#### Database Connection Issues

1. Verify security group rules
2. Check RDS instance status
3. Validate connection string and credentials
4. Test connectivity from ECS tasks

#### Frontend Not Loading

1. Check S3 bucket policy and CORS
2. Verify CloudFront distribution status
3. Check DNS resolution
4. Validate SSL certificate

#### High Response Times

1. Check ECS CPU/memory utilization
2. Review database performance metrics
3. Analyze slow query logs
4. Consider scaling resources

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster CLUSTER_NAME --services SERVICE_NAME

# View ECS task logs
aws logs tail /aws/ecs/work-tracker-staging/backend --follow

# Check RDS status
aws rds describe-db-instances --db-instance-identifier work-tracker-staging-postgres

# Test API health
curl -f https://api.worktracker.example.com/health

# View CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=work-tracker-staging-backend \
  --start-time 2023-01-01T00:00:00Z \
  --end-time 2023-01-01T01:00:00Z \
  --period 300 \
  --statistics Average
```

## Support and Maintenance

### Regular Maintenance Tasks

- **Weekly**: Review CloudWatch alarms and metrics
- **Monthly**: Update dependencies and security patches
- **Quarterly**: Review and optimize costs
- **Annually**: Review and update disaster recovery procedures

### Backup and Recovery

- **RDS**: Automated daily backups with 7-day retention
- **Application Data**: Export functionality for user data
- **Infrastructure**: Terraform state stored in S3 with versioning

### Disaster Recovery

1. **RDS**: Point-in-time recovery available
2. **Application**: Multi-AZ deployment for high availability
3. **Frontend**: CloudFront provides global distribution
4. **Infrastructure**: Terraform enables quick recreation

For additional support, refer to the monitoring runbook created during setup or contact the DevOps team.