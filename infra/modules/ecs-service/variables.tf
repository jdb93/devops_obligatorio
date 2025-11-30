variable "cluster_arn" {
  type = string
}

variable "service_name" {
  type = string
}

variable "task_def_arn" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}

variable "target_group_arn" {
  type = string
}

variable "container_name" {
  type = string
}

variable "container_port" {
  type = number
}

variable "desired_count" {
  type    = number
  default = 1
}