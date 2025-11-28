resource "aws_security_group" "alb_public" {
  name   = "alb-public-sg-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    description = "Allow HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs" {
  name   = "ecs-stockwiz-sg-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    description     = "Inbound requests from ALB to API Gateway"
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

resource "aws_security_group" "db" {
  name   = "stockwiz-db-sg-${var.environment}"
  vpc_id = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description     = "Postgres access from ECS tasks"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lambda_sql_init" {
  name        = "lambda-sql-init-sg"
  description = "Security Group for Lambda to initialize PostgreSQL"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lambda-sql-init-sg"
  }
}

# 🟢 REGLA CORRECTA: Lambda → Postgres (vía SG del ECS)
resource "aws_security_group_rule" "lambda_to_postgres" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"

  security_group_id        = aws_security_group.db.id         # ← CORRECTO
  source_security_group_id = aws_security_group.lambda_sql_init.id
}



