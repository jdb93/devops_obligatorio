############################################
# SG del ALB (público)
#############################################
resource "aws_security_group" "alb_public" {
  name   = "alb-public-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow outbound anywhere
  }
}

#############################################
# SG del API Gateway (solo accesible por ALB)
#############################################
resource "aws_security_group" "api" {
  name   = "api-gateway-sg"
  vpc_id = var.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#############################################
# SG de microservicios Product/Inventory
#############################################
resource "aws_security_group" "services" {
  name   = "services-sg"
  vpc_id = var.vpc_id

  # Product Service (8001) - desde API Gateway **y** desde ALB
  ingress {
    description = "Product service from API Gateway and ALB"
    from_port   = 8001
    to_port     = 8001
    protocol    = "tcp"
    security_groups = [
      aws_security_group.api.id,
      aws_security_group.alb_public.id
    ]
  }

  # Inventory Service (8002) - desde API Gateway **y** desde ALB
  ingress {
    description = "Inventory service from API Gateway and ALB"
    from_port   = 8002
    to_port     = 8002
    protocol    = "tcp"
    security_groups = [
      aws_security_group.api.id,
      aws_security_group.alb_public.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


#############################################
# SG de base de datos Postgres (solo desde microservicios)
#############################################
resource "aws_security_group" "db" {
  name   = "stockwiz-db-sg-${var.environment}"
  vpc_id = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description     = "Postgres from ECS services"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.services.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
