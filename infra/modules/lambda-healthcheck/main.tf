data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

resource "aws_lambda_function" "healthcheck" {
  function_name = "${var.app_name}-${var.environment}-healthcheck"
  handler       = "lambda.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lab_role.arn

  filename         = "${path.root}/../lambda-healthcheck/lambda-healthcheck.zip"
  source_code_hash = filebase64sha256("${path.root}/../lambda-healthcheck/lambda-healthcheck.zip")

  environment {
    variables = {
      ALB_URL = var.alb_dns_name
    }
  }
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name        = "${var.app_name}-${var.environment}-healthcheck-schedule"
  description = "Runs Lambda every 5 minutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "target" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.healthcheck.arn
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.healthcheck.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
