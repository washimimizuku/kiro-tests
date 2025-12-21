# ============================================================================
# Staging Environment Configuration
# ============================================================================

# General Configuration
aws_region  = "us-east-1"
environment = "staging"

# Domain Configuration (optional for staging)
domain_name         = ""  # Use CloudFront domain for staging
acm_certificate_arn = ""  # No custom certificate for staging

# Network Configuration
vpc_cidr = "10.1.0.0/16"

# RDS Configuration (smaller for staging)
rds_instance_class          = "db.t3.micro"
rds_allocated_storage       = 20
rds_multi_az               = false  # Single AZ for cost savings
rds_backup_retention_period = 3

# Database Configuration
database_name     = "work_tracker_staging"
database_username = "work_tracker_user"

# ElastiCache Configuration (smaller for staging)
redis_node_type   = "cache.t3.micro"
redis_num_nodes   = 1

# ECS Configuration (smaller for staging)
backend_image         = "work-tracker-backend:latest"  # Will be updated by CI/CD
backend_cpu           = 256
backend_memory        = 512
backend_desired_count = 1

# Cognito Configuration
cognito_callback_urls = [
  "https://staging-worktracker.example.com/auth/callback",
  "http://localhost:3000/auth/callback"
]
cognito_logout_urls = [
  "https://staging-worktracker.example.com/auth/logout",
  "http://localhost:3000/auth/logout"
]

# Monitoring Configuration
alarm_email = "devops@example.com"