# ============================================================================
# ElastiCache Module - Redis Cache
# ============================================================================

# Security Group for ElastiCache
resource "aws_security_group" "redis" {
  name_prefix = "${var.name_prefix}-${var.environment}-redis-"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.environment}-redis-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ElastiCache Parameter Group
resource "aws_elasticache_parameter_group" "redis" {
  family = "redis7.x"
  name   = "${var.name_prefix}-${var.environment}-redis7"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  tags = var.tags
}

# ElastiCache Replication Group
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = "${var.name_prefix}-${var.environment}-redis"
  description                = "Redis cluster for Work Tracker ${var.environment}"

  # Node configuration
  node_type               = var.node_type
  port                    = 6379
  parameter_group_name    = aws_elasticache_parameter_group.redis.name

  # Cluster configuration
  num_cache_clusters      = var.num_cache_nodes
  
  # Network configuration
  subnet_group_name       = var.cache_subnet_group_name
  security_group_ids      = [aws_security_group.redis.id]

  # Security
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result

  # Backup configuration
  snapshot_retention_limit = 3
  snapshot_window         = "03:00-05:00"
  maintenance_window      = "sun:05:00-sun:07:00"

  # Automatic failover (requires at least 2 nodes)
  automatic_failover_enabled = var.num_cache_nodes > 1

  # Logging
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "slow-log"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-${var.environment}-redis"
  })
}

# Generate random auth token for Redis
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

# Store auth token in AWS Secrets Manager
resource "aws_secretsmanager_secret" "redis_auth_token" {
  name                    = "${var.name_prefix}-${var.environment}-redis-auth-token"
  description             = "Redis auth token for Work Tracker"
  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "redis_auth_token" {
  secret_id     = aws_secretsmanager_secret.redis_auth_token.id
  secret_string = jsonencode({
    auth_token = random_password.redis_auth_token.result
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "redis_slow" {
  name              = "/aws/elasticache/redis/${var.name_prefix}-${var.environment}/slow-log"
  retention_in_days = 7

  tags = var.tags
}