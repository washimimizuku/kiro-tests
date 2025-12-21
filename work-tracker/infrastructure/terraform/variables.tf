# ============================================================================
# General Configuration
# ============================================================================

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Domain name for the application"
  type        = string
  default     = "worktracker.example.com"
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ============================================================================
# RDS Configuration
# ============================================================================

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for RDS"
  type        = bool
  default     = true
}

variable "rds_backup_retention_period" {
  description = "RDS backup retention period in days"
  type        = number
  default     = 7
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "work_tracker"
}

variable "database_username" {
  description = "Database master username"
  type        = string
  default     = "work_tracker_user"
}

# ============================================================================
# ElastiCache Configuration
# ============================================================================

variable "redis_node_type" {
  description = "ElastiCache Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_num_nodes" {
  description = "Number of Redis cache nodes"
  type        = number
  default     = 1
}

# ============================================================================
# ECS Configuration
# ============================================================================

variable "backend_image" {
  description = "Docker image for backend service"
  type        = string
  default     = "work-tracker-backend:latest"
}

variable "backend_cpu" {
  description = "CPU units for backend service"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memory for backend service in MB"
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "Desired number of backend service instances"
  type        = number
  default     = 2
}

# ============================================================================
# Cognito Configuration
# ============================================================================

variable "cognito_callback_urls" {
  description = "Cognito callback URLs"
  type        = list(string)
  default     = ["https://worktracker.example.com/auth/callback"]
}

variable "cognito_logout_urls" {
  description = "Cognito logout URLs"
  type        = list(string)
  default     = ["https://worktracker.example.com/auth/logout"]
}

# ============================================================================
# Monitoring Configuration
# ============================================================================

variable "alarm_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = "admin@example.com"
}