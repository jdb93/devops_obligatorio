# 🔐 API Gateway SG (público)
resource "aws_security_group" "api_sg" {
  name        = "stockwiz-${var.environment}-api-sg"
  description = "Public access to API Gateway"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = var.api_port
    to_port     = var.api_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "api-sg-${var.environment}"
    Environment = var.environment
    Project     = "StockWiz"
  }
}

# 🔒 Product SG (solo accesible desde API Gateway)
resource "aws_security_group" "product_sg" {
  name        = "stockwiz-${var.environment}-product-sg"
  description = "Only API Gateway can call Product Service"
  vpc_id      = var.vpc_id

  ingress {
    description = "API -> Product"
    from_port   = var.product_port
    to_port     = var.product_port
    protocol    = "tcp"
    security_groups = [aws_security_group.api_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "product-sg-${var.environment}"
    Environment = var.environment
    Project     = "StockWiz"
  }
}

# 🔐 Inventory SG (solo accesible desde API Gateway)
resource "aws_security_group" "inventory_sg" {
  name        = "stockwiz-${var.environment}-inventory-sg"
  description = "Only API Gateway can call Inventory Service"
  vpc_id      = var.vpc_id

  ingress {
    description = "API -> Inventory"
    from_port   = var.inventory_port
    to_port     = var.inventory_port
    protocol    = "tcp"
    security_groups = [aws_security_group.api_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "inventory-sg-${var.environment}"
    Environment = var.environment
    Project     = "StockWiz"
  }
}
