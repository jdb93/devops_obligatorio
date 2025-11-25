data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_ecs_task_definition" "task" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode(
    concat(
      [
        merge(
          {
            name        = var.name
            image       = "${var.image}:latest"
            essential   = true
            environment = var.environment

            #👇 Solo agrega dependsOn cuando hay extra_containers (redis)
            dependsOn = length(var.extra_containers) > 0 ? [
              for c in var.extra_containers : {
                containerName = c.name
                condition     = "START"
              }
            ] : null

            portMappings = [
              { containerPort = var.port, protocol = "tcp" }
            ]
          },
          {
            logConfiguration = {
              logDriver = "awslogs"
              options = {
                awslogs-group         = "/ecs/${var.name}"
                awslogs-region        = var.region
                awslogs-stream-prefix = var.name
              }
            }
          }
        )
      ],
      [
        for c in var.extra_containers : merge(
          c,
          {
            image      = "${c.image}:latest"
            essential  = false

            logConfiguration = {
              logDriver = "awslogs"
              options = {
                awslogs-group         = "/ecs/${var.name}"
                awslogs-region        = var.region
                awslogs-stream-prefix = "${var.name}-sidecar"
              }
            }
          }
        )
      ]
    )
  )
}

resource "aws_ecs_service" "service" {
  name            = var.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.task.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  force_new_deployment               = true

  network_configuration {
    assign_public_ip = var.public
    subnets          = var.subnets
    security_groups  = var.security_groups
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.name
    container_port   = var.port
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
