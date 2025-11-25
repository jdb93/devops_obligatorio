variable "region" {
  default = "us-east-1"
}

variable "profile" {
  default = "default"
}

variable "app_name" {
  description = "Prefijo común para los recursos"
  type        = string
  default     = "stockwiz-dev"
}

variable "account_id" {
  description = "Tu AWS Account ID (el de AWS Academy)"
  type        = string
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet CIDRs"
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet CIDRs"
}
