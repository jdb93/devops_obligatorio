output "sg_alb" {
  value = aws_security_group.alb_public.id
}

output "sg_ecs" {
  value = aws_security_group.ecs.id
}


output "sg_db" {
  value = aws_security_group.db.id
}

output "sg_lambda_sql_init" {
  value = aws_security_group.lambda_sql_init.id
}
