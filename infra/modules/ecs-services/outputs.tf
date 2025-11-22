output "ecs_service_name" {
  value = aws_ecs_service.this.name
}

output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "api_sg_id" {
  value = aws_security_group.api_sg.id
}

output "product_sg_id" {
  value = aws_security_group.product_sg.id
}

output "inventory_sg_id" {
  value = aws_security_group.inventory_sg.id
}
