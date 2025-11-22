terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "180358-stockwiz-backend"
    key    = "stockwiz/terraform.tfstate"
    region = "us-east-1"
  }
}

module "vpc" {
  source              = "./modules/vpc"
  environment         = var.environment
  vpc_cidr_block      = var.vpc_cidr_block
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones  = var.availability_zones
  tags                = var.tags
}


module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
  tags        = var.tags
}

module "ecs" {
  source              = "./modules/ecs"
  environment         = var.environment
  public_subnet_ids   = module.vpc.public_subnet_ids
  instance_type       = var.instance_type
  desired_capacity    = var.instance_count
  max_capacity        = 2
  instance_profile_name = "LabInstanceProfile"
}

module "security" {
  source      = "./modules/security"
  environment = var.environment
  vpc_id      = module.vpc.vpc_id
}

module "alb" {
  source            = "./modules/alb"
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  tags              = var.tags
}
