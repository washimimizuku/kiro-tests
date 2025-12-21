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
}

provider "aws" {
  region = var.aws_region
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
}