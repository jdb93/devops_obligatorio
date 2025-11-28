#############################################
# IAM ROLE (LabRole Permission)
#############################################
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

#############################################
# CLOUDWATCH LOG GROUPS (1 POR CONTENEDOR)
#############################################
resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/api-gateway"
  retention_in_days = 7
  lifecycle { ignore_changes = [name] }
}

resource "aws_cloudwatch_log_group" "product" {
  name              = "/ecs/product-service"
  retention_in_days = 7
  lifecycle { ignore_changes = [name] }
}

resource "aws_cloudwatch_log_group" "inventory" {
  name              = "/ecs/inventory-service"
  retention_in_days = 7
  lifecycle { ignore_changes = [name] }
}

resource "aws_cloudwatch_log_group" "redis" {
  name              = "/ecs/redis"
  retention_in_days = 7
  lifecycle { ignore_changes = [name] }
}

resource "aws_cloudwatch_log_group" "postgres" {
  name              = "/ecs/postgres"
  retention_in_days = 7
  lifecycle { ignore_changes = [name] }
}

#############################################
# ECS TASK DEFINITION (MULTI-CONTAINER)
#############################################
resource "aws_ecs_task_definition" "stockwiz" {
  family                   = "${var.project_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "2048"
  memory                   = "4096"
  execution_role_arn       = data.aws_iam_role.lab_role.arn
  task_role_arn            = data.aws_iam_role.lab_role.arn

  container_definitions = jsonencode([

    ### ================= API GATEWAY ================= ###
    {
      name      = "api-gateway"
      image     = "${var.ecr_repo_urls["api-gateway"]}:latest"
      essential = true
      cpu       = 512
      memory    = 1024

      portMappings = [{ containerPort = 8000 }]

      # Usa localhost igual que en los defaults del main.go
      environment = [
        { name = "PRODUCT_SERVICE_URL",   value = "http://localhost:8001" },
        { name = "INVENTORY_SERVICE_URL", value = "http://localhost:8002" },
        { name = "REDIS_URL",             value = "localhost:6379" },
        { name = "DATABASE_URL",          value = var.database_url }
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
  command = [
    "CMD-SHELL",
    "curl -f http://localhost:8000/health || exit 1"
  ]
  interval    = 10
  timeout     = 5
  retries     = 3
  startPeriod = 20
}


      dependsOn = [
        { containerName = "redis",             condition = "HEALTHY" },
        { containerName = "postgres",          condition = "HEALTHY" },
        { containerName = "product-service",   condition = "HEALTHY" },
        { containerName = "inventory-service", condition = "HEALTHY" }
      ]
    },

    ### ================= PRODUCT SERVICE ================= ###
    {
      name      = "product-service"
      image     = "${var.ecr_repo_urls["product-service"]}:latest"
      essential = true
      cpu       = 256
      memory    = 512

      portMappings = [{ containerPort = 8001 }]

      # FastAPI: usa DATABASE_URL con scheme postgres/postgresql
      # y REDIS_URL con scheme redis://
      environment = [
        { name = "DATABASE_URL", value = var.database_url },
        { name = "REDIS_URL",    value = "redis://localhost:6379" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/product-service"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      # La imagen no tiene curl, pero sí python: usamos python para el healthcheck
healthCheck = {
  command = [
    "CMD-SHELL",
    "python -c \"import urllib.request,sys; r=urllib.request.urlopen('http://localhost:8001/health'); sys.exit(0) if r.getcode()==200 else sys.exit(1)\""
  ]
  interval    = 10
  timeout     = 5
  retries     = 3
  startPeriod = 15
}



      dependsOn = [
        { containerName = "redis",    condition = "HEALTHY" },
        { containerName = "postgres", condition = "HEALTHY" }
      ]
    },

    ### ================= INVENTORY SERVICE ================= ###
    {
      name      = "inventory-service"
      image     = "${var.ecr_repo_urls["inventory-service"]}:latest"
      essential = true
      cpu       = 256
      memory    = 512

      portMappings = [{ containerPort = 8002 }]

      # Go service: espera DATABASE_URL estilo postgres://... y REDIS_URL sin scheme
      environment = [
        { name = "DATABASE_URL", value = var.database_url },
        { name = "REDIS_URL",    value = "localhost:6379" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/inventory-service"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      # La imagen sí tiene wget (busybox), y el Dockerfile ya usa wget en HEALTHCHECK.
      # Replicamos eso para ECS:
      healthCheck = {
        command     = ["CMD-SHELL", "wget -qO- http://localhost:8002/health || exit 1"]
        interval    = 10
        timeout     = 5
        retries     = 3
        startPeriod = 15
      }

      dependsOn = [
        { containerName = "redis",    condition = "HEALTHY" },
        { containerName = "postgres", condition = "HEALTHY" }
      ]
    },

    ### ================= REDIS ================= ###
    {
      name      = "redis"
      image     = "${var.ecr_repo_urls["redis"]}:latest"
      essential = true
      cpu       = 256
      memory    = 512

      portMappings = [{ containerPort = 6379 }]
      command      = ["redis-server", "--appendonly", "yes"]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/redis"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD", "redis-cli", "ping"]
        interval    = 10
        timeout     = 5
        retries     = 3
        startPeriod = 15
      }
    },

    ### ================= POSTGRES ================= ###
    {
      name      = "postgres"
      image     = "${var.ecr_repo_urls["postgres"]}:latest"
      essential = true
      cpu       = 512
      memory    = 1024

      portMappings = [{ containerPort = 5432 }]

      environment = [
        { name = "POSTGRES_USER",     value = var.db_username },
        { name = "POSTGRES_PASSWORD", value = var.db_password },
        { name = "POSTGRES_DB",       value = var.db_name }
      ]

      command = [
  "postgres",
  "-c", "listen_addresses=*",
  "-c", "max_connections=100"
]


      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/postgres"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "pg_isready -h localhost -p 5432 || exit 1"]
        interval    = 15
        timeout     = 10
        retries     = 10
        startPeriod = 90
      }
    }
  ])
}

#############################################
# OUTPUT
#############################################
output "task_def_arn" {
  value = aws_ecs_task_definition.stockwiz.arn
}
