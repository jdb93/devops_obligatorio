terraform {
  required_version = ">= 1.5.0"
  # backend "s3" está en backend.tf (lo dejas igual)
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

locals {
  # URLs de imágenes ECR (repos pre-creados a mano)
  ecr_repo_urls = {
  api-gateway       = "339713009539.dkr.ecr.us-east-1.amazonaws.com/stockwiz-api-gateway-dev"
  product-service   = "339713009539.dkr.ecr.us-east-1.amazonaws.com/stockwiz-product-service-dev"
  inventory-service = "339713009539.dkr.ecr.us-east-1.amazonaws.com/stockwiz-inventory-service-dev"
}
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
  cluster_name = var.app_name
}

# --- RDS Postgres ---
module "rds" {
  source                 = "./modules/rds"
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  private_subnet_ids     = module.vpc.private_subnets
  vpc_security_group_ids = [module.security.sg_db]
}

# --- ALB público apuntando al API Gateway ---
module "alb" {
  source           = "./modules/alb"
  vpc_id           = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnets
  security_group_id = module.security.sg_alb
  app_name          = var.app_name
}

# --- Task Definition multi-container ---
module "ecs_task" {
  source        = "./modules/ecs-task"
  project_name  = var.app_name
  region        = var.region
  db_name = var.db_name
  db_password   = var.db_password
  db_username   = var.db_username
  rds_endpoint  = module.rds.endpoint
  ecr_repo_urls = local.ecr_repo_urls
}

# --- ECS Service (1 service, 1 ALB, 1 TaskDefinition con 4 containers) ---
module "ecs_service" {
  source           = "./modules/ecs-service"
  cluster_arn      = module.ecs_cluster.cluster_arn
  service_name     = "${var.app_name}-svc"
  task_def_arn     = module.ecs_task.task_def_arn
  private_subnets  = module.vpc.private_subnets
  security_groups  = [module.security.sg_ecs]
  target_group_arn = module.alb.target_group_arn
  container_name   = "api-gateway"
  container_port   = 8000
}

module "ecr" {
  source       = "./modules/ecr"
  app_name     = var.app_name
  environment  = var.environment
  services     = ["api-gateway", "product-service", "inventory-service"]
}
