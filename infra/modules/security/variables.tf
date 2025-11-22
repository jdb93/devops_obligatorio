variable "vpc_id" {
  description = "VPC where security groups will be created"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}
