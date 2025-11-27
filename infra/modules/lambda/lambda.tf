locals {
  lambda_name = "${var.app_name}-db-init-${var.environment}"
}

resource "aws_security_group" "lambda_sql_init" {
  name        = "${local.lambda_name}-sg"
  description = "Lambda SG to access PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "lambda_to_db" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.security.db_sg_id
  source_security_group_id = aws_security_group.lambda_sql_init.id
}

resource "aws_lambda_function" "db_init" {
  filename         = "${path.module}/lambda.zip"
  function_name    = local.lambda_name
  role             = data.aws_iam_role.lab_role.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.9"
  timeout          = 15
  memory_size      = 128

  environment {
    variables = {
      DATABASE_URL = var.database_url
    }
  }

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda_sql_init.id]
  }
}
