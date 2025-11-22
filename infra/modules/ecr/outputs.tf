output "api_gateway_repository_url" {
  value = aws_ecr_repository.api_gateway.repository_url
}

output "product_service_repository_url" {
  value = aws_ecr_repository.product_service.repository_url
}

output "inventory_service_repository_url" {
  value = aws_ecr_repository.inventory_service.repository_url
}
