output "alb_dns" {
  description = "Public DNS of the ALB"
  value       = aws_lb.this.dns_name
}

output "api_target_group_arn" {
  description = "Target group ARN for API Gateway"
  value       = aws_lb_target_group.api_tg.arn
}

output "alb_security_group_id" {
  description = "Security Group ID for ALB"
  value       = aws_security_group.alb_sg.id
}
