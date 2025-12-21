# Work Tracker AWS Infrastructure

This Terraform configuration deploys the complete AWS infrastructure for the Work Tracker application, including:

- **VPC** with public, private, database, and cache subnets across multiple AZs
- **RDS PostgreSQL** with Multi-AZ deployment and automated backups
- **ElastiCache Redis** for session and query caching
- **ECS Fargate** cluster for containerized backend services
- **Application Load Balancer** for traffic distribution
- **S3 + CloudFront** for frontend static file hosting
- **AWS Cognito** for user authentication
- **CloudWatch** monitoring and alerting
- **IAM roles** and security policies

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **Domain name** registered and managed in Route 53 (optional)
4. **ACM certificate** for HTTPS (optional but recommended)

## Quick Start

1. **Clone and navigate to the infrastructure directory:**
   ```bash
   cd work-tracker/infrastructure/terraform
   ```

2. **Copy and customize the variables file:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Plan the deployment:**
   ```bash
   terraform plan
   ```

5. **Apply the infrastructure:**
   ```bash
   terraform apply
   ```

## Configuration

### Required Variables

Edit `terraform.tfvars` with your specific values:

```hcl
# Basic Configuration
aws_region  = "us-east-1"
environment = "prod"
alarm_email = "admin@yourdomain.com"

# Domain Configuration (optional)
domain_name         = "worktracker.yourdomain.com"
acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/..."

# Backend Image (update after building and pushing to ECR)
backend_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/work-tracker-backend:latest"
```

### Environment-Specific Configurations

For different environments (dev, staging, prod), create separate `.tfvars` files:

```bash
# Development
terraform apply -var-file="dev.tfvars"

# Staging
terraform apply -var-file="staging.tfvars"

# Production
terraform apply -var-file="prod.tfvars"
```

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐
│   CloudFront    │────│   S3 Bucket      │
│   (Frontend)    │    │   (Static Files) │
└─────────────────┘    └──────────────────┘
         │
         ▼
┌─────────────────┐    ┌──────────────────┐
│       ALB       │────│   ECS Fargate    │
│   (API Gateway) │    │   (Backend API)  │
└─────────────────┘    └──────────────────┘
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────────┐
│   RDS Postgres  │    │  ElastiCache     │
│   (Database)    │    │   (Redis Cache)  │
└─────────────────┘    └──────────────────┘
```

## Security Features

- **VPC** with private subnets for backend services
- **Security Groups** with least-privilege access
- **RDS encryption** at rest and in transit
- **Redis encryption** at rest and in transit
- **Secrets Manager** for database and Redis credentials
- **IAM roles** with minimal required permissions
- **CloudFront** with Origin Access Control (OAC)

## Monitoring and Alerting

The infrastructure includes comprehensive monitoring:

- **CloudWatch Dashboard** with key metrics
- **CloudWatch Alarms** for:
  - ECS CPU/Memory utilization
  - RDS performance metrics
  - ALB response times and error rates
  - Application error rates
- **SNS notifications** sent to configured email

## Backup and Recovery

- **RDS automated backups** with configurable retention
- **Point-in-time recovery** for RDS
- **Multi-AZ deployment** for high availability
- **ECS service** with auto-scaling and health checks

## Cost Optimization

- **Fargate Spot** instances for non-critical workloads
- **RDS storage autoscaling** to optimize costs
- **CloudFront caching** to reduce origin requests
- **S3 lifecycle policies** for log retention

## Deployment Process

1. **Build and push Docker images** to ECR
2. **Update terraform.tfvars** with new image URIs
3. **Apply Terraform changes** to update ECS services
4. **Deploy frontend** to S3 and invalidate CloudFront

## Troubleshooting

### Common Issues

1. **Certificate validation timeout:**
   - Ensure DNS records are properly configured
   - Certificate must be in us-east-1 for CloudFront

2. **ECS service fails to start:**
   - Check CloudWatch logs for container errors
   - Verify environment variables and secrets

3. **Database connection issues:**
   - Ensure security groups allow traffic
   - Check VPC and subnet configurations

### Useful Commands

```bash
# View current infrastructure state
terraform show

# Import existing resources
terraform import aws_instance.example i-1234567890abcdef0

# Destroy infrastructure (be careful!)
terraform destroy

# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate
```

## Outputs

After successful deployment, Terraform provides important outputs:

- **ALB DNS name** for API access
- **CloudFront domain** for frontend access
- **RDS endpoint** for database connections
- **Cognito User Pool IDs** for authentication setup

## Support

For issues with the infrastructure:

1. Check CloudWatch logs and metrics
2. Review Terraform state and plan output
3. Consult AWS documentation for service-specific issues
4. Contact your DevOps team for assistance