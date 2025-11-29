resource "aws_sns_topic" "alerts" {
  name = "${var.app_name}-${var.environment}-alerts"
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.app_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # CPU ECS
      {
        "type" : "metric",
        "x" : 0, "y" : 0, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "CPU Utilization ECS",
          "metrics" : [
            ["AWS/ECS", "CPUUtilization",
              "ClusterName", var.ecs_cluster_name,
              "ServiceName", var.ecs_service_name
            ]
          ],
          "stat" : "Average",
          "period" : 300,
          "region" : var.aws_region
        }
      },

      # Memory ECS
      {
        "type" : "metric",
        "x" : 12, "y" : 0, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Memory Utilization ECS",
          "metrics" : [
            ["AWS/ECS", "MemoryUtilization",
              "ClusterName", var.ecs_cluster_name,
              "ServiceName", var.ecs_service_name
            ]
          ],
          "stat" : "Average",
          "period" : 300,
          "region" : var.aws_region
        }
      },

      # ALB Latency
      {
        "type" : "metric",
        "x" : 0, "y" : 6, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Target Response Time (ALB)",
          "metrics" : [
            ["AWS/ApplicationELB", "TargetResponseTime",
              "LoadBalancer", var.alb_arn_suffix
            ]
          ],
          "stat" : "Average",
          "period" : 300,
          "region" : var.aws_region
        }
      },

      # Count de requests
      {
        "type" : "metric",
        "x" : 12, "y" : 6, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Request Count (ALB)",
          "metrics" : [
            ["AWS/ApplicationELB", "RequestCount",
              "LoadBalancer", var.alb_arn_suffix
            ]
          ],
          "stat" : "Sum",
          "period" : 300,
          "region" : var.aws_region
        }
      },

      # hosts healthy
      {
        "type" : "metric",
        "x" : 0, "y" : 12, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "Healthy Hosts (Target Group)",
          "metrics" : [
            ["AWS/ApplicationELB", "HealthyHostCount",
              "LoadBalancer", var.alb_arn_suffix,
              "TargetGroup", var.target_group_arn_suffix
            ]
          ],
          "stat" : "Average",
          "period" : 300,
          "region" : var.aws_region
        }
      },

      # 5XX ALB
      {
        "type" : "metric",
        "x" : 12, "y" : 12, "width" : 12, "height" : 6,
        "properties" : {
          "title" : "HTTP 5XX (Target)",
          "metrics" : [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count",
              "LoadBalancer", var.alb_arn_suffix
            ]
          ],
          "stat" : "Sum",
          "period" : 300,
          "region" : var.aws_region
        }
      }
    ]
  })
}


resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.app_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_description = "CPU > 80% durante 10 minutos"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.app_name}-${var.environment}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_description = "5xx en el ALB mayor a 5 en 1 minuto"
  alarm_actions     = [aws_sns_topic.alerts.arn]
  ok_actions        = [aws_sns_topic.alerts.arn]
}
