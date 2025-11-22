######################################
# IAM Role lookup (LabRole de Academy)
######################################
data "aws_iam_role" "ecs_role" {
  name = "LabRole"
}

######################################
# ECS Task Definition
######################################
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.container_name}-${var.environment}"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"

  cpu    = 256
  memory = 512

  execution_role_arn = data.aws_iam_role.ecs_role.arn
  task_role_arn      = data.aws_iam_role.ecs_role.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.image_url
      essential = true
      cpu       = 256
      memory    = 512

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
    }
  ])
}

######################################
# ECS Service
######################################
resource "aws_ecs_service" "this" {
  name            = "${var.container_name}-${var.environment}"
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "EC2"
  desired_count   = 1

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [var.security_group_id]
    assign_public_ip = false
  }

  force_new_deployment = true

  depends_on = [aws_ecs_task_definition.this]
}

######################################
# Security Groups
######################################

# API Gateway SG (público)
resource "aws_security_group" "api_sg" {
  name        = "stockwiz-${var.environment}-api-sg"
  description = "Allow HTTP traffic for API Gateway"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.api_port
    to_port     = var.api_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Público
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Product Service SG (acceso SOLO desde API)
resource "aws_security_group" "product_sg" {
  name        = "stockwiz-${var.environment}-product-sg"
  description = "Only API Gateway can access Product Service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.product_port
    to_port         = var.product_port
    protocol        = "tcp"
    security_groups = [aws_security_group.api_sg.id] # <-- SOLO desde el API
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Inventory Service SG (acceso SOLO desde API)
resource "aws_security_group" "inventory_sg" {
  name        = "stockwiz-${var.environment}-inventory-sg"
  description = "Only API Gateway can access Inventory Service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.inventory_port
    to_port         = var.inventory_port
    protocol        = "tcp"
    security_groups = [aws_security_group.api_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
