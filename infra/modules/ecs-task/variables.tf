variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "rds_endpoint" {
  type = string
}

variable "ecr_repo_urls" {
  type = map(string)
}
