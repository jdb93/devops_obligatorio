##############################################
# Security Group para ALB (público)
##############################################
resource "aws_security_group" "alb_sg" {
  name        = "stockwiz-${var.environment}-alb-sg"
  description = "Allow public HTTP"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere"
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

  tags = var.tags
}

##############################################
# Application Load Balancer
##############################################
resource "aws_lb" "this" {
  name               = "stockwiz-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  tags = var.tags
}

##############################################
# Target Group para API Gateway
##############################################
resource "aws_lb_target_group" "api_tg" {
  name     = "stockwiz-${var.environment}-api-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = var.tags
}

##############################################
# Listener public listener 80 -> API Gateway TG
##############################################
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }
}
