variable "app_name" {}
variable "environment" {}
variable "services" {
  type = list(string)
}

resource "aws_ecr_repository" "repos" {
  for_each = toset(var.services)

  name = "${var.app_name}-${each.key}-${var.environment}"

  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}
