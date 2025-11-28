variable "region" {
  type = string
}

variable "profile" {
  type    = string
  default = "default"
}


variable "app_name" {
  type = string
  # Ej: "stockwiz-dev", "stockwiz-stg", "stockwiz-prod"
}

variable "environment" {
  type = string
  # Ej: "dev", "stg", "prod"
}

variable "cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

# RDS
variable "db_name" {
  type = string
  # Ej: "stockwiz_dev", "stockwiz_stg", "stockwiz_prod"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "ecr_repo_urls" {
  type = map(string)
}

variable "database_url" {
  type = string
  description = "Connection string for Postgres (used by Lambda init)"
}

variable "desired_count" {
  type = number
  default = 1
}

variable "bucket_name" {}
variable "db_url" {}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}
