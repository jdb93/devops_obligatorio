resource "aws_ecs_service" "this" {
  name            = var.service_name
  cluster         = var.cluster_arn
  task_definition = var.task_def_arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnets
    security_groups = var.security_groups
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  health_check_grace_period_seconds = 120
}
