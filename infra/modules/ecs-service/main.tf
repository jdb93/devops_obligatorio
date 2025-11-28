resource "aws_ecs_service" "this" {
  cluster        = var.cluster_arn
  name           = var.service_name
  task_definition = var.task_def_arn
   desired_count = var.desired_count

  launch_type = "FARGATE"

  network_configuration {
    subnets         = var.private_subnets
    security_groups = var.security_groups  # ← SOLO ESTO
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}

