#!/bin/bash

# ============================================================================
# Work Tracker Monitoring Setup Script
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
EMAIL=""

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

Set up monitoring and alerting for Work Tracker application

OPTIONS:
    -e, --environment ENV    Target environment (staging|prod) [default: staging]
    -r, --region REGION      AWS region [default: us-east-1]
    --email EMAIL           Email address for alerts (required)
    -h, --help              Show this help message

EXAMPLES:
    $0 --email admin@example.com                    # Setup monitoring for staging
    $0 -e prod --email alerts@example.com          # Setup monitoring for production

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
        --email)
            EMAIL="$2"
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

# Validate required parameters
if [[ -z "$EMAIL" ]]; then
    print_error "Email address is required for alerts"
    show_usage
    exit 1
fi

if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "prod" ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be 'staging' or 'prod'"
    exit 1
fi

# Create CloudWatch custom metrics
create_custom_metrics() {
    print_status "Creating custom CloudWatch metrics..."
    
    # Application performance metrics
    aws logs put-metric-filter \
        --log-group-name "/aws/ecs/work-tracker-$ENVIRONMENT/backend" \
        --filter-name "work-tracker-$ENVIRONMENT-response-time" \
        --filter-pattern "[timestamp, request_id, level, message=\"Response time:\", duration]" \
        --metric-transformations \
            metricName=ResponseTime,metricNamespace="WorkTracker/$ENVIRONMENT",metricValue='$duration',unit=Milliseconds
    
    # Database query metrics
    aws logs put-metric-filter \
        --log-group-name "/aws/ecs/work-tracker-$ENVIRONMENT/backend" \
        --filter-name "work-tracker-$ENVIRONMENT-db-queries" \
        --filter-pattern "[timestamp, request_id, level, message=\"Database query:\", query_time]" \
        --metric-transformations \
            metricName=DatabaseQueryTime,metricNamespace="WorkTracker/$ENVIRONMENT",metricValue='$query_time',unit=Milliseconds
    
    # User activity metrics
    aws logs put-metric-filter \
        --log-group-name "/aws/ecs/work-tracker-$ENVIRONMENT/backend" \
        --filter-name "work-tracker-$ENVIRONMENT-user-activities" \
        --filter-pattern "[timestamp, request_id, level, message=\"Activity created:\", user_id]" \
        --metric-transformations \
            metricName=ActivitiesCreated,metricNamespace="WorkTracker/$ENVIRONMENT",metricValue=1,unit=Count
    
    print_success "Custom metrics created"
}

# Create additional CloudWatch alarms
create_additional_alarms() {
    print_status "Creating additional CloudWatch alarms..."
    
    # Get SNS topic ARN
    SNS_TOPIC_ARN=$(aws sns list-topics --query "Topics[?contains(TopicArn, 'work-tracker-$ENVIRONMENT-alerts')].TopicArn" --output text)
    
    if [[ -z "$SNS_TOPIC_ARN" ]]; then
        print_error "SNS topic not found. Make sure infrastructure is deployed first."
        exit 1
    fi
    
    # High response time alarm
    aws cloudwatch put-metric-alarm \
        --alarm-name "work-tracker-$ENVIRONMENT-high-response-time" \
        --alarm-description "High API response time" \
        --metric-name ResponseTime \
        --namespace "WorkTracker/$ENVIRONMENT" \
        --statistic Average \
        --period 300 \
        --threshold 2000 \
        --comparison-operator GreaterThanThreshold \
        --evaluation-periods 2 \
        --alarm-actions "$SNS_TOPIC_ARN" \
        --treat-missing-data notBreaching
    
    # High database query time alarm
    aws cloudwatch put-metric-alarm \
        --alarm-name "work-tracker-$ENVIRONMENT-slow-db-queries" \
        --alarm-description "Slow database queries" \
        --metric-name DatabaseQueryTime \
        --namespace "WorkTracker/$ENVIRONMENT" \
        --statistic Average \
        --period 300 \
        --threshold 1000 \
        --comparison-operator GreaterThanThreshold \
        --evaluation-periods 2 \
        --alarm-actions "$SNS_TOPIC_ARN" \
        --treat-missing-data notBreaching
    
    # Low user activity alarm (for business metrics)
    aws cloudwatch put-metric-alarm \
        --alarm-name "work-tracker-$ENVIRONMENT-low-user-activity" \
        --alarm-description "Low user activity detected" \
        --metric-name ActivitiesCreated \
        --namespace "WorkTracker/$ENVIRONMENT" \
        --statistic Sum \
        --period 3600 \
        --threshold 5 \
        --comparison-operator LessThanThreshold \
        --evaluation-periods 2 \
        --alarm-actions "$SNS_TOPIC_ARN" \
        --treat-missing-data breaching
    
    print_success "Additional alarms created"
}

# Create CloudWatch Insights queries
create_insights_queries() {
    print_status "Creating CloudWatch Insights saved queries..."
    
    # Error analysis query
    aws logs put-query-definition \
        --name "work-tracker-$ENVIRONMENT-error-analysis" \
        --log-group-names "/aws/ecs/work-tracker-$ENVIRONMENT/backend" \
        --query-string 'fields @timestamp, @message, level, request_id
| filter level = "ERROR"
| sort @timestamp desc
| limit 100'
    
    # Performance analysis query
    aws logs put-query-definition \
        --name "work-tracker-$ENVIRONMENT-performance-analysis" \
        --log-group-names "/aws/ecs/work-tracker-$ENVIRONMENT/backend" \
        --query-string 'fields @timestamp, @message, duration
| filter @message like /Response time:/
| stats avg(duration), max(duration), min(duration) by bin(5m)
| sort @timestamp desc'
    
    # User activity analysis query
    aws logs put-query-definition \
        --name "work-tracker-$ENVIRONMENT-user-activity" \
        --log-group-names "/aws/ecs/work-tracker-$ENVIRONMENT/backend" \
        --query-string 'fields @timestamp, @message, user_id
| filter @message like /Activity created:/
| stats count() by user_id
| sort count desc
| limit 20'
    
    # API endpoint usage query
    aws logs put-query-definition \
        --name "work-tracker-$ENVIRONMENT-api-usage" \
        --log-group-names "/aws/ecs/work-tracker-$ENVIRONMENT/backend" \
        --query-string 'fields @timestamp, @message, method, path, status_code
| filter @message like /Request:/
| stats count() by path, method
| sort count desc
| limit 50'
    
    print_success "CloudWatch Insights queries created"
}

# Create custom dashboard
create_custom_dashboard() {
    print_status "Creating custom CloudWatch dashboard..."
    
    # Get resource identifiers
    CLUSTER_NAME="work-tracker-$ENVIRONMENT-cluster"
    SERVICE_NAME="work-tracker-$ENVIRONMENT-backend"
    
    # Create dashboard JSON
    cat > /tmp/dashboard.json << EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "WorkTracker/$ENVIRONMENT", "ResponseTime" ],
                    [ ".", "DatabaseQueryTime" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$AWS_REGION",
                "title": "Application Performance",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ "WorkTracker/$ENVIRONMENT", "ActivitiesCreated" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "$AWS_REGION",
                "title": "User Activity",
                "period": 300,
                "stat": "Sum"
            }
        },
        {
            "type": "log",
            "x": 0,
            "y": 6,
            "width": 24,
            "height": 6,
            "properties": {
                "query": "SOURCE '/aws/ecs/work-tracker-$ENVIRONMENT/backend'\n| fields @timestamp, level, @message\n| filter level = \"ERROR\"\n| sort @timestamp desc\n| limit 20",
                "region": "$AWS_REGION",
                "title": "Recent Errors",
                "view": "table"
            }
        }
    ]
}
EOF
    
    # Create the dashboard
    aws cloudwatch put-dashboard \
        --dashboard-name "work-tracker-$ENVIRONMENT-custom" \
        --dashboard-body file:///tmp/dashboard.json
    
    # Clean up
    rm /tmp/dashboard.json
    
    print_success "Custom dashboard created"
}

# Setup log retention
setup_log_retention() {
    print_status "Setting up log retention policies..."
    
    # Set retention for ECS logs
    aws logs put-retention-policy \
        --log-group-name "/aws/ecs/work-tracker-$ENVIRONMENT/backend" \
        --retention-in-days 14
    
    # Set retention for ALB logs (if exists)
    if aws logs describe-log-groups --log-group-name-prefix "/aws/elasticloadbalancing" --query "logGroups[?contains(logGroupName, 'work-tracker-$ENVIRONMENT')]" --output text | grep -q "work-tracker"; then
        aws logs put-retention-policy \
            --log-group-name "/aws/elasticloadbalancing/work-tracker-$ENVIRONMENT" \
            --retention-in-days 7
    fi
    
    print_success "Log retention policies configured"
}

# Create monitoring runbook
create_runbook() {
    print_status "Creating monitoring runbook..."
    
    cat > "work-tracker-$ENVIRONMENT-runbook.md" << EOF
# Work Tracker $ENVIRONMENT Monitoring Runbook

## Overview
This runbook provides guidance for monitoring and troubleshooting the Work Tracker application in the $ENVIRONMENT environment.

## Key Metrics to Monitor

### Application Performance
- **Response Time**: Average API response time should be < 2 seconds
- **Database Query Time**: Average query time should be < 1 second
- **Error Rate**: Should be < 1% of total requests

### Infrastructure Health
- **ECS CPU Utilization**: Should be < 80%
- **ECS Memory Utilization**: Should be < 85%
- **RDS CPU Utilization**: Should be < 75%
- **ALB Response Time**: Should be < 2 seconds

### Business Metrics
- **User Activities Created**: Monitor for unusual drops in user activity
- **API Endpoint Usage**: Track most used endpoints

## Alarm Response Procedures

### High Response Time
1. Check ECS service health and task count
2. Review CloudWatch Insights for slow queries
3. Check RDS performance metrics
4. Consider scaling ECS service if needed

### Database Issues
1. Check RDS CPU and memory utilization
2. Review slow query logs
3. Check connection count
4. Consider read replica if needed

### High Error Rate
1. Check application logs for error patterns
2. Review recent deployments
3. Check external service dependencies
4. Consider rollback if recent deployment

### Low User Activity
1. Check if it's expected (maintenance, holidays)
2. Verify frontend is accessible
3. Check authentication service
4. Review user feedback channels

## Useful CloudWatch Insights Queries

### Error Analysis
\`\`\`
fields @timestamp, @message, level, request_id
| filter level = "ERROR"
| sort @timestamp desc
| limit 100
\`\`\`

### Performance Analysis
\`\`\`
fields @timestamp, @message, duration
| filter @message like /Response time:/
| stats avg(duration), max(duration), min(duration) by bin(5m)
| sort @timestamp desc
\`\`\`

### User Activity
\`\`\`
fields @timestamp, @message, user_id
| filter @message like /Activity created:/
| stats count() by user_id
| sort count desc
| limit 20
\`\`\`

## Dashboard Links
- Main Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#dashboards:name=work-tracker-$ENVIRONMENT-dashboard
- Custom Dashboard: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#dashboards:name=work-tracker-$ENVIRONMENT-custom

## Contact Information
- Primary: $EMAIL
- Escalation: DevOps Team
- Emergency: On-call rotation

## Maintenance Windows
- Staging: Anytime (with notification)
- Production: Sundays 2-4 AM UTC (with advance notice)

EOF
    
    print_success "Runbook created: work-tracker-$ENVIRONMENT-runbook.md"
}

# Main function
main() {
    print_status "Setting up monitoring for Work Tracker $ENVIRONMENT environment"
    print_status "AWS Region: $AWS_REGION"
    print_status "Alert Email: $EMAIL"
    
    create_custom_metrics
    create_additional_alarms
    create_insights_queries
    create_custom_dashboard
    setup_log_retention
    create_runbook
    
    print_success "🎉 Monitoring setup completed successfully!"
    print_status "Dashboard URL: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#dashboards:name=work-tracker-$ENVIRONMENT-custom"
    print_status "Runbook created: work-tracker-$ENVIRONMENT-runbook.md"
}

# Run main function
main