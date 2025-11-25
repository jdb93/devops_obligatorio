variable "name" {
  description = "Nombre del ECS Service y Task Definition"
  type        = string
}

variable "cluster_id" {
  description = "ID del ECS Cluster donde se desplegará el servicio"
  type        = string
}

variable "image" {
  description = "URL de la imagen de container en ECR o Docker Hub"
  type        = string
}

variable "port" {
  description = "Puerto expuesto por el container y target group"
  type        = number
}

variable "cpu" {
  description = "CPU asignada a la tarea (en unidades Fargate)"
  type        = number
  default     = 256 # 0.25 vCPU
}

variable "memory" {
  description = "Memoria asignada a la tarea (en MB)"
  type        = number
  default     = 512
}

variable "public" {
  description = "Indica si el servicio necesita IP pública (solo API Gateway)"
  type        = bool
  default     = false
}

variable "subnets" {
  description = "Lista de subnets donde se ejecutará el servicio"
  type        = list(string)
}

variable "security_groups" {
  description = "Security groups asignados al servicio"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN del Target Group asociado al Load Balancer"
  type        = string
}

variable "desired_count" {
  type        = number
  default     = 1
  description = "Cantidad de tareas a ejecutar en el servicio ECS"
}

variable "extra_containers" {
  description = "Contenedores adicionales (sidecars) que se agregan al Task Definition"
  type = any
  default     = []
}

variable "environment" {
  description = "Variables de entorno para el contenedor principal"
  type        = list(map(string))
  default     = []
}

variable "region" {
  type = string
}

