output "api_gateway_sg_id" {
  value = aws_security_group.api_gateway_sg.id
}

output "internal_services_sg_id" {
  value = aws_security_group.internal_services_sg.id
}
