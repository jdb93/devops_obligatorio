variable "bucket_name" {}
variable "db_url" {}
variable "private_subnets" {
  type = list(string)
}
variable "lambda_sg_id" {
  type = string
}

data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_s3_object" "lambda_zip" {
  bucket = var.bucket_name
  key    = "lambda-db-init.zip"
  source = "${path.root}/../lambda-db-init/lambda-db-init.zip"
  etag   = filemd5("${path.root}/../lambda-db-init/lambda-db-init.zip")
}

resource "aws_lambda_function" "db_init" {
  function_name = "stockwiz-db-init"
  handler       = "handler.lambda_handler"
  runtime       = "python3.11"
  role          = data.aws_iam_role.lab_role.arn

  s3_bucket        = aws_s3_object.lambda_zip.bucket
  s3_key           = aws_s3_object.lambda_zip.key
  source_code_hash = filebase64sha256("${path.root}/../lambda-db-init/lambda-db-init.zip")

  timeout     = 30
  memory_size = 256

  # 🔥 AHORA SÍ LA LAMBDA ENTRA EN LA VPC 🔥
  vpc_config {
    subnet_ids         = var.private_subnets   # ["subnet-0f...", "subnet-03..."]
    security_group_ids = [var.lambda_sg_id]    # sg de la lambda
  }

  environment {
    variables = {
      DATABASE_URL = var.db_url
    }
  }
}
