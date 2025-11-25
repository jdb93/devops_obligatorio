# ------------------------ Application Load Balancer ------------------------
resource "aws_lb" "app_alb" {
  name               = "stockwiz-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.sg_alb]
  subnets            = var.public_subnets

  enable_deletion_protection = false
}

# ------------------------ Target Groups ------------------------

# API Gateway (public entrypoint via ALB)
resource "aws_lb_target_group" "api_tg" {
  name        = "api-gateway-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

health_check {
  enabled             = true
  interval            = 30
  timeout             = 10
  healthy_threshold   = 2
  unhealthy_threshold = 5
  matcher             = "200-399"
  path                = "/"
  port                = "traffic-port"
  protocol            = "HTTP"
}

}

# Product microservice (private)
resource "aws_lb_target_group" "product_tg" {
  name        = "product-tg"
  port        = 8001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 20
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 10
}
}

# Inventory microservice (private)
resource "aws_lb_target_group" "inventory_tg" {
  name        = "inventory-tg"
  port        = 8002
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 20
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# ------------------------ Listener ------------------------
resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api_tg.arn
  }
}

########################################
# Listener Rules para cada microservicio
########################################

# /product → product-service TG
resource "aws_lb_listener_rule" "product_rule" {
  listener_arn = aws_lb_listener.listener_http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.product_tg.arn
  }

  condition {
    path_pattern {
      values = ["/product*"]
    }
  }
}

# /inventory → inventory-service TG
resource "aws_lb_listener_rule" "inventory_rule" {
  listener_arn = aws_lb_listener.listener_http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.inventory_tg.arn
  }

  condition {
    path_pattern {
      values = ["/inventory*"]
    }
  }
}
