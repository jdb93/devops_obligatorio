variable "environment" {
  description = "Environment name such as dev, staging, prod"
  type        = string
}

variable "tags" {
  description = "Tags to apply to ECR repositories"
  type        = map(string)
  default     = {}
}
