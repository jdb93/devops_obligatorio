data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/api-gateway"
  retention_in_days = 7

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_cloudwatch_log_group" "product" {
  name              = "/ecs/product-service"
  retention_in_days = 7

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_cloudwatch_log_group" "inventory" {
  name              = "/ecs/inventory-service"
  retention_in_days = 7

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "/ecs/redis"
  retention_in_days = 7

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_ecs_task_definition" "stockwiz" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    {
      name      = "api-gateway"
      image     = "${var.ecr_repo_urls["api-gateway"]}:latest"
      essential = true
      cpu       = 1024
      memory    = 2048

      portMappings = [
        {
          containerPort = 8000
        }
      ]

      environment = [
        # Dentro del mismo task, todos comparten red => usamos localhost
        { name = "PRODUCT_SERVICE_URL",   value = "http://localhost:8001" },
        { name = "INVENTORY_SERVICE_URL", value = "http://localhost:8002" },
        # Go: host:port, sin esquema
        { name = "REDIS_URL",             value = "localhost:6379" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/api-gateway"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      dependsOn = [
        # Esperamos a que Redis esté OK antes de arrancar el gateway
        { containerName = "redis",            condition = "HEALTHY" },
        { containerName = "product-service",  condition = "START" },
        { containerName = "inventory-service", condition = "START" }
      ]
    },
    {
      name      = "product-service"
      image     = "${var.ecr_repo_urls["product-service"]}:latest"
      essential = true
      cpu       = 256
      memory    = 512

      portMappings = [
        {
          containerPort = 8001
        }
      ]

      environment = [
        {
          name  = "DATABASE_URL"
          # FastAPI/asyncpg: usamos postgresql:// como en docker-compose
          value = "postgresql://${var.db_username}:${var.db_password}@${var.rds_endpoint}:5432/${var.db_name}"
        },
        {
          # Python redis async: necesita esquema redis://
          name  = "REDIS_URL"
          value = "redis://localhost:6379"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/product-service"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      dependsOn = [
        # Esperamos a que Redis esté healthy antes de levantar
        { containerName = "redis", condition = "HEALTHY" }
      ]
    },
    {
      name      = "inventory-service"
      image     = "${var.ecr_repo_urls["inventory-service"]}:latest"
      essential = true
      cpu       = 256
      memory    = 512

      portMappings = [
        {
          containerPort = 8002
        }
      ]

      environment = [
        {
          name  = "DATABASE_URL"
          # Go: igual que en docker-compose, con sslmode=disable
          value = "postgres://${var.db_username}:${var.db_password}@${var.rds_endpoint}:5432/${var.db_name}?sslmode=disable"
        },
        {
          # Go redis client: host:port, sin esquema
          name  = "REDIS_URL"
          value = "localhost:6379"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/inventory-service"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      dependsOn = [
        { containerName = "redis", condition = "HEALTHY" }
      ]
    },
    {
      name      = "redis"
      image = "339713009539.dkr.ecr.us-east-1.amazonaws.com/redis:7-alpine"
      essential = true
      cpu       = 256
      memory    = 512

      portMappings = [
        {
          containerPort = 6379
        }
      ]

      # Imitamos el docker-compose: appendonly activado
      command = [
        "redis-server",
        "--appendonly",
        "yes"
      ]

      healthCheck = {
        command     = ["CMD", "redis-cli", "ping"]
        interval    = 10
        timeout     = 5
        retries     = 3
        startPeriod = 15
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/redis"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

output "task_def_arn" {
  value = aws_ecs_task_definition.stockwiz.arn
}
