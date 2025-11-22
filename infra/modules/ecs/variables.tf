variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where ECS EC2 instances will run"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for ECS instances"
  type        = string
  default     = "t3.micro"
}

variable "desired_capacity" {
  description = "Number of EC2 instances in the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of EC2 instances for scaling"
  type        = number
  default     = 2
}

variable "instance_profile_name" {
  description = "Existing IAM Instance Profile name (LabInstanceProfile)"
  type        = string
  default     = "LabInstanceProfile"
}
