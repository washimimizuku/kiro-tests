output "cicd_role_arn" {
  description = "CI/CD role ARN"
  value       = aws_iam_role.cicd.arn
}

output "lambda_role_arn" {
  description = "Lambda role ARN"
  value       = aws_iam_role.lambda.arn
}

output "events_role_arn" {
  description = "CloudWatch Events role ARN"
  value       = aws_iam_role.events.arn
}

output "backup_role_arn" {
  description = "Backup service role ARN"
  value       = aws_iam_role.backup.arn
}

output "bedrock_policy_arn" {
  description = "Bedrock access policy ARN"
  value       = var.bedrock_enabled ? aws_iam_policy.bedrock_access[0].arn : null
}