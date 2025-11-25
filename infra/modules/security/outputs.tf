# SG del ALB público
output "sg_alb_public" {
  value = aws_security_group.alb_public.id
}

# SG del API Gateway
output "sg_api" {
  value = aws_security_group.api.id
}

# SG de microservicios privados
output "sg_services" {
  value = aws_security_group.services.id
}

output "sg_db" {
  value = aws_security_group.db.id
}
