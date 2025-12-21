# Work Tracker AWS Infrastructure Configuration
# This Terraform configuration sets up the complete AWS infrastructure
# for the Work Tracker application following the design document

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "work-tracker-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "work-tracker-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = local.common_tags
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Local values
locals {
  name_prefix = "work-tracker"
  common_tags = {
    Project     = "WorkTracker"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
  
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# ============================================================================
# VPC and Networking
# ============================================================================

module "vpc" {
  source = "./modules/vpc"
  
  name_prefix         = local.name_prefix
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = local.azs
  
  tags = local.common_tags
}

# ============================================================================
# RDS PostgreSQL Database
# ============================================================================

module "rds" {
  source = "./modules/rds"
  
  name_prefix                 = local.name_prefix
  environment                 = var.environment
  vpc_id                      = module.vpc.vpc_id
  database_subnet_ids         = module.vpc.database_subnet_ids
  database_subnet_group_name  = module.vpc.database_subnet_group_name
  allowed_security_groups     = [module.ecs.ecs_security_group_id]
  
  instance_class              = var.rds_instance_class
  allocated_storage           = var.rds_allocated_storage
  multi_az                    = var.rds_multi_az
  backup_retention_period     = var.rds_backup_retention_period
  
  database_name               = var.database_name
  master_username             = var.database_username
  
  tags = local.common_tags
}

# ============================================================================
# ElastiCache Redis
# ============================================================================

module "elasticache" {
  source = "./modules/elasticache"
  
  name_prefix               = local.name_prefix
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  cache_subnet_ids          = module.vpc.cache_subnet_ids
  cache_subnet_group_name   = module.vpc.cache_subnet_group_name
  allowed_security_groups   = [module.ecs.ecs_security_group_id]
  
  node_type                 = var.redis_node_type
  num_cache_nodes           = var.redis_num_nodes
  
  tags = local.common_tags
}

# ============================================================================
# Application Load Balancer
# ============================================================================

module "alb" {
  source = "./modules/alb"
  
  name_prefix         = local.name_prefix
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  certificate_arn     = var.acm_certificate_arn
  
  tags = local.common_tags
}

# ============================================================================
# ECS Fargate Cluster and Services
# ============================================================================

module "ecs" {
  source = "./modules/ecs"
  
  name_prefix           = local.name_prefix
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_target_group_arn  = module.alb.target_group_arn
  alb_security_group_id = module.alb.alb_security_group_id
  
  # Backend service configuration
  backend_image         = var.backend_image
  backend_cpu           = var.backend_cpu
  backend_memory        = var.backend_memory
  backend_desired_count = var.backend_desired_count
  
  # Environment variables
  database_url          = module.rds.database_url
  redis_url             = module.elasticache.redis_url
  aws_region            = var.aws_region
  cognito_user_pool_id  = module.cognito.user_pool_id
  cognito_client_id     = module.cognito.user_pool_client_id
  
  tags = local.common_tags
}

# ============================================================================
# S3 and CloudFront for Frontend
# ============================================================================

module "frontend" {
  source = "./modules/frontend"
  
  name_prefix         = local.name_prefix
  environment         = var.environment
  domain_name         = var.domain_name
  certificate_arn     = var.acm_certificate_arn
  alb_domain_name     = module.alb.alb_dns_name
  
  tags = local.common_tags
}

# ============================================================================
# AWS Cognito for Authentication
# ============================================================================

module "cognito" {
  source = "./modules/cognito"
  
  name_prefix         = local.name_prefix
  environment         = var.environment
  callback_urls       = var.cognito_callback_urls
  logout_urls         = var.cognito_logout_urls
  
  tags = local.common_tags
}

# ============================================================================
# IAM Roles and Policies
# ============================================================================

module "iam" {
  source = "./modules/iam"
  
  name_prefix         = local.name_prefix
  environment         = var.environment
  bedrock_enabled     = true
  
  tags = local.common_tags
}

# ============================================================================
# CloudWatch Monitoring and Alarms
# ============================================================================

module "monitoring" {
  source = "./modules/monitoring"
  
  name_prefix         = local.name_prefix
  environment         = var.environment
  
  # ECS monitoring
  ecs_cluster_name    = module.ecs.cluster_name
  ecs_service_name    = module.ecs.service_name
  
  # RDS monitoring
  rds_instance_id     = module.rds.instance_id
  
  # ALB monitoring
  alb_arn_suffix      = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  
  # Alert configuration
  alarm_email         = var.alarm_email
  
  tags = local.common_tags
}

# ============================================================================
# Outputs
# ============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = module.frontend.cloudfront_domain_name
}

output "rds_endpoint" {
  description = "RDS database endpoint"
  value       = module.rds.endpoint
  sensitive   = true
}

output "redis_endpoint" {
  description = "Redis cache endpoint"
  value       = module.elasticache.redis_endpoint
  sensitive   = true
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.cognito.user_pool_client_id
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend"
  value       = module.frontend.s3_bucket_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ecs.service_name
}