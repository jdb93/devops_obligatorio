locals {
  common_tags = merge(
    {
      Project     = "stockwiz"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_ecr_repository" "api_gateway" {
  name = "stockwiz-${var.environment}-api-gateway"

  tags = local.common_tags
}

resource "aws_ecr_repository" "product_service" {
  name = "stockwiz-${var.environment}-product-service"

  tags = local.common_tags
}

resource "aws_ecr_repository" "inventory_service" {
  name = "stockwiz-${var.environment}-inventory-service"

  tags = local.common_tags
}
