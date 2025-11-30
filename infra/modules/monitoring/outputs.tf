output "dashboard_name" {
  description = "Nombre del dashboard creado en CloudWatch"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "sns_topic_arn" {
  description = "ARN del SNS Topic para alertas"
  value       = aws_sns_topic.alerts.arn
}
