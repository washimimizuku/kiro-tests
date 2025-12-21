output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "alarm_arns" {
  description = "List of CloudWatch alarm ARNs"
  value = [
    aws_cloudwatch_metric_alarm.ecs_cpu_high.arn,
    aws_cloudwatch_metric_alarm.ecs_memory_high.arn,
    aws_cloudwatch_metric_alarm.ecs_task_count_low.arn,
    aws_cloudwatch_metric_alarm.rds_cpu_high.arn,
    aws_cloudwatch_metric_alarm.rds_connections_high.arn,
    aws_cloudwatch_metric_alarm.rds_free_storage_low.arn,
    aws_cloudwatch_metric_alarm.alb_response_time_high.arn,
    aws_cloudwatch_metric_alarm.alb_5xx_errors_high.arn,
    aws_cloudwatch_metric_alarm.alb_healthy_hosts_low.arn,
    aws_cloudwatch_metric_alarm.application_errors_high.arn
  ]
}