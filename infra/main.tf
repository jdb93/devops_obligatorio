terraform {
  required_version = ">= 1.5.0"
}

provider "aws" {
  region  = var.region
  profile = var.profile
}


# --- VPC ---
module "vpc" {
  source          = "./modules/vpc"
  cidr            = var.cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  environment     = var.environment
  tags            = var.tags
}

# --- Security Groups ---
module "security" {
  source      = "./modules/security"
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

# --- ECS Cluster ---
module "ecs_cluster" {
  source       = "./modules/ecs-cluster"
  cluster_name = "${var.app_name}-${var.environment}"
}

# --- ALB público apuntando al API Gateway ---
module "alb" {
  source           = "./modules/alb"
  vpc_id           = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnets
  security_group_id = module.security.sg_alb
  app_name          = var.app_name
  environment = var.environment
}


module "ecs_task" {
  source         = "./modules/ecs-task"
  project_name   = var.app_name
  region         = var.region
  ecr_repo_urls  = module.ecr.repository_urls 
  db_username    = var.db_username
  db_password    = var.db_password
  db_name        = var.db_name
  database_url   = var.database_url
}



# --- ECS Service (1 service, 1 ALB, 1 TaskDefinition con 4 containers) ---
module "ecs_service" {
  source           = "./modules/ecs-service"
  cluster_arn      = module.ecs_cluster.cluster_arn
  service_name     = "${var.app_name}-svc-${var.environment}"
  task_def_arn     = module.ecs_task.task_def_arn
  private_subnets  = module.vpc.private_subnets
  desired_count = var.desired_count

  security_groups  = [
    module.security.sg_ecs,
    module.security.sg_db
  ]

  target_group_arn = module.alb.target_group_arn
  container_name   = "api-gateway"
  container_port   = 8000
}

module "ecr" {
  source       = "./modules/ecr"
  app_name     = var.app_name
  environment  = var.environment
  services     = ["api-gateway", "product-service", "inventory-service", "redis", "postgres"]
}

module "lambda_healthcheck" {
  source       = "./modules/lambda-healthcheck"
  app_name     = var.app_name
  environment  = var.environment
  alb_dns_name = module.alb.dns_name
}

module "monitoring" {
  source = "./modules/monitoring"

  aws_region = var.region
  app_name   = var.app_name
  environment = var.environment

  ecs_cluster_name = module.ecs_cluster.cluster_name
  ecs_service_name = "${var.app_name}-svc-${var.environment}"

  alb_arn_suffix           = module.alb.arn_suffix
  target_group_arn_suffix  = module.alb.target_group_arn_suffix
}
