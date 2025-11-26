variable "region" {
  type = string
}

variable "profile" {
  type    = string
  default = "default"
}

variable "account_id" {
  type = string
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