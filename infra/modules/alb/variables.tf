variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnets" {
  description = "Subnets públicas para el ALB"
  type        = list(string)
}

variable "sg_alb" {
  description = "Security Group del ALB"
  type        = string
}
