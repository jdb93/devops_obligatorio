data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# ---------- CloudWatch Logs ----------
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

resource "aws_cloudwatch_log_group" "postgres" {
  name              = "/ecs/postgres"
  retention_in_days = 7

  lifecycle {
    ignore_changes = [name]
  }
}

# ---------- Task Definition ----------
resource "aws_ecs_task_definition" "stockwiz" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([
    # ================= API GATEWAY =================
    {
      name      = "api-gateway"
      image     = "${var.ecr_repo_urls["api-gateway"]}:latest"
      essential = true
      cpu       = 512
      memory    = 1024

      portMappings = [{ containerPort = 8000 }]

      environment = [
        { name = "PRODUCT_SERVICE_URL",   value = "http://localhost:8001" },
        { name = "INVENTORY_SERVICE_URL", value = "http://localhost:8002" },
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

      healthCheck = {
  command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
  interval    = 10
  timeout     = 5
  retries     = 3
  startPeriod = 15
}


      dependsOn = [
  { containerName = "redis",             condition = "HEALTHY" },
  { containerName = "postgres",          condition = "HEALTHY" },
  { containerName = "product-service",   condition = "HEALTHY" },
  { containerName = "inventory-service", condition = "HEALTHY" }
]

    },

    # ================= PRODUCT SERVICE =================
    {
      name      = "product-service"
      image     = "${var.ecr_repo_urls["product-service"]}:latest"
      essential = true
      cpu       = 256
      memory    = 512

      portMappings = [{ containerPort = 8001 }]

      environment = [
        { name = "DATABASE_URL",  value = "postgresql://${var.db_username}:${var.db_password}@localhost:5432/${var.db_name}?sslmode=disable" },
        { name = "DB_PORT",       value = "5432" },
        { name = "DB_USER",       value = var.db_username },
        { name = "DB_PASSWORD",   value = var.db_password },
        { name = "DB_NAME",       value = var.db_name },
        { name = "REDIS_URL",     value = "redis://localhost:6379" }
      ]

      healthCheck = {
  command     = ["CMD-SHELL", "curl -f http://localhost:8001/health || exit 1"]
  interval    = 10
  timeout     = 5
  retries     = 3
  startPeriod = 15
}


      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/product-service"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      dependsOn = [
  { containerName = "redis",    condition = "HEALTHY" },
  { containerName = "postgres", condition = "HEALTHY" }
]

    },

    # ================= INVENTORY SERVICE =================
    {
      name      = "inventory-service"
      image     = "${var.ecr_repo_urls["inventory-service"]}:latest"
      essential = true
      cpu       = 256
      memory    = 512

      portMappings = [{ containerPort = 8002 }]

      environment = [
        { name = "DATABASE_URL",  value = "postgres://${var.db_username}:${var.db_password}@localhost:5432/${var.db_name}?sslmode=disable" },
        { name = "DB_PORT",       value = "5432" },
        { name = "DB_USER",       value = var.db_username },
        { name = "DB_PASSWORD",   value = var.db_password },
        { name = "DB_NAME",       value = var.db_name },
        { name = "REDIS_URL",     value = "localhost:6379" }
      ]

      healthCheck = {
  command     = ["CMD-SHELL", "curl -f http://localhost:8002/health || exit 1"]
  interval    = 10
  timeout     = 5
  retries     = 3
  startPeriod = 15
}


      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/inventory-service"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      dependsOn = [
  { containerName = "redis",    condition = "HEALTHY" },
  { containerName = "postgres", condition = "HEALTHY" }
]

    },

    # ================= REDIS =================
    {
      name      = "redis"
      image = "${var.ecr_repo_urls["redis"]}:latest"
      essential = true
      cpu       = 256
      memory    = 512

      portMappings = [{ containerPort = 6379 }]

      command = ["redis-server", "--appendonly", "yes"]

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
    },

    # ================= POSTGRES =================
    {
      name      = "postgres"
      image = "${var.ecr_repo_urls["postgres"]}:latest"
      essential = true
      cpu       = 512
      memory    = 1024

      portMappings = [{ containerPort = 5432 }]

      environment = [
        { name = "POSTGRES_USER",     value = var.db_username },
        { name = "POSTGRES_PASSWORD", value = var.db_password },
        { name = "POSTGRES_DB",       value = var.db_name }
      ]

      command = ["postgres"]

      healthCheck = {
        command     = ["CMD-SHELL", "pg_isready -h localhost -p 5432 || exit 1"]
        interval    = 15
        timeout     = 10
        retries     = 10
        startPeriod = 90
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/postgres"
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
