variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "service_name" {
  description = "Name of the ECS Service"
  type        = string
}

variable "container_name" {
  description = "Container name inside the task"
  type        = string
}

variable "image_url" {
  description = "ECR Image URL"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
}

variable "subnet_ids" {
  description = "Subnets where ECS tasks will run (public or private)"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group assigned to the task"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS services run"
  type        = string
}

variable "api_port" {
  description = "Port of API Gateway service"
  type        = number
  default     = 8000
}

variable "product_port" {
  description = "Port of Product service"
  type        = number
  default     = 8001
}

variable "inventory_port" {
  description = "Port of Inventory service"
  type        = number
  default     = 8002
}