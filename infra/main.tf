terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

# ============================================================
#                               VPC
# ============================================================

module "vpc" {
  source          = "./modules/vpc"
  environment     = var.environment
  cidr            = var.cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# ============================================================
#                         SECURITY GROUPS
# ============================================================

module "security" {
  source      = "./modules/security"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

# ============================================================
#                         ECS CLUSTER
# ============================================================

module "ecs_cluster" {
  source = "./modules/ecs-cluster"
  name   = var.app_name
}

# ============================================================
#                        ECR REPOSITORIES
# ============================================================

resource "aws_ecr_repository" "repos" {
  for_each = toset([
    "api-gateway",
    "product-service",
    "inventory-service"
  ])

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# ============================================================
#              ALB + TARGET GROUPS (Público por defecto)
# ============================================================

module "alb" {
  source         = "./modules/alb"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  sg_alb         = module.security.sg_alb_public

  depends_on = [module.security]
}

# ============================================================
#                        RDS POSTGRES
# ============================================================

resource "aws_db_subnet_group" "stockwiz" {
  name       = "stockwiz-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_instance" "stockwiz" {
  identifier             = "stockwiz-dev-db"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "stockwizdb"
  username               = "stockwiz"
  password               = "stockwiz123"
  db_subnet_group_name   = aws_db_subnet_group.stockwiz.name
  vpc_security_group_ids = [module.security.sg_db]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

# ============================================================
#                             SERVICES
# ============================================================

# -------- API GATEWAY (CON REDIS SIDE-CAR ÚNICO) -------------
module "svc_api_gateway" {
  source = "./modules/ecs-service"

  name             = "api-gateway"
  cluster_id       = module.ecs_cluster.id
  image            = aws_ecr_repository.repos["api-gateway"].repository_url
  port             = 8000
  public           = true
  memory           = 2048
  cpu              = 1024

  subnets          = module.vpc.public_subnets
  security_groups  = [module.security.sg_api]
  target_group_arn = module.alb.tg_api_arn
  region           = var.region

  environment = [
    { name = "PRODUCT_SERVICE_URL",   value = "http://${module.alb.alb_dns_name}/product" },
    { name = "INVENTORY_SERVICE_URL", value = "http://${module.alb.alb_dns_name}/inventory" },
    { name = "REDIS_URL",             value = "redis://localhost:6379" }
  ]

  extra_containers = [
    {
      name        = "redis"
      image       = "redis:7-alpine"
      environment = []
      portMappings = [
        {
          containerPort = 6379
          protocol      = "tcp"
        }
      ]
    }
  ]

  depends_on = [module.alb]
}

# -------- PRODUCT SERVICE (SIN REDIS) -------------
module "svc_product" {
  source = "./modules/ecs-service"

  name             = "product-service"
  cluster_id       = module.ecs_cluster.id
  image            = aws_ecr_repository.repos["product-service"].repository_url
  port             = 8001
  public           = false
  memory           = 2048
  cpu              = 1024

  subnets          = module.vpc.private_subnets
  security_groups  = [module.security.sg_services]
  target_group_arn = module.alb.tg_product_arn
  region           = var.region

  environment = [
    { name = "DATABASE_URL", value = "postgres://stockwiz:stockwiz123@${aws_db_instance.stockwiz.address}:5432/stockwizdb?sslmode=require" }
  ]

  extra_containers = []

  depends_on = [module.alb, aws_db_instance.stockwiz]
}

# -------- INVENTORY SERVICE (SIN REDIS) -------------
module "svc_inventory" {
  source = "./modules/ecs-service"

  name             = "inventory-service"
  cluster_id       = module.ecs_cluster.id
  image            = aws_ecr_repository.repos["inventory-service"].repository_url
  port             = 8002
  public           = false
  memory           = 2048
  cpu              = 1024

  subnets          = module.vpc.private_subnets
  security_groups  = [module.security.sg_services]
  target_group_arn = module.alb.tg_inventory_arn
  region           = var.region

  environment = [
    { name = "DATABASE_URL", value = "postgres://stockwiz:stockwiz123@${aws_db_instance.stockwiz.address}:5432/stockwizdb?sslmode=require" }
  ]

  extra_containers = []

  depends_on = [module.alb, aws_db_instance.stockwiz]
}

# ============================================================
#                              OUTPUTS
# ============================================================

output "alb_url" {
  value = "http://${module.alb.alb_dns_name}"
}
