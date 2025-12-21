# ============================================================================
# Production Environment Configuration
# ============================================================================

# General Configuration
aws_region  = "us-east-1"
environment = "prod"

# Domain Configuration
domain_name         = "worktracker.example.com"
acm_certificate_arn = "arn:aws:acm:us-east-1:ACCOUNT-ID:certificate/CERTIFICATE-ID"

# Network Configuration
vpc_cidr = "10.0.0.0/16"

# RDS Configuration (production-ready)
rds_instance_class          = "db.t3.small"
rds_allocated_storage       = 100
rds_multi_az               = true
rds_backup_retention_period = 7

# Database Configuration
database_name     = "work_tracker"
database_username = "work_tracker_user"

# ElastiCache Configuration (production-ready)
redis_node_type   = "cache.t3.small"
redis_num_nodes   = 2

# ECS Configuration (production-ready)
backend_image         = "work-tracker-backend:latest"  # Will be updated by CI/CD
backend_cpu           = 512
backend_memory        = 1024
backend_desired_count = 2

# Cognito Configuration
cognito_callback_urls = [
  "https://worktracker.example.com/auth/callback"
]
cognito_logout_urls = [
  "https://worktracker.example.com/auth/logout"
]

# Monitoring Configuration
alarm_email = "alerts@example.com"