data "aws_ami" "ecs" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# -----------------------------
# ECS Cluster
# -----------------------------
resource "aws_ecs_cluster" "this" {
  name = "stockwiz-${var.environment}-cluster"
}

# -----------------------------
# Launch Template (EC2 for ECS)
# -----------------------------
resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "stockwiz-${var.environment}-lt"
  image_id      = data.aws_ami.ecs.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name  # <<< CORRECTO: LabInstanceProfile
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    cluster_name = aws_ecs_cluster.this.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Environment = var.environment
      Project     = "StockWiz"
    }
  }
}

# -----------------------------
# Auto Scaling Group
# -----------------------------
resource "aws_autoscaling_group" "ecs_asg" {
  name                = "stockwiz-${var.environment}-asg"

  vpc_zone_identifier = var.public_subnet_ids

  desired_capacity    = var.desired_capacity
  min_size            = 1
  max_size            = var.max_capacity
  protect_from_scale_in = false

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "StockWiz"
    propagate_at_launch = true
  }
}

# -----------------------------
# Capacity Provider
# -----------------------------
resource "aws_ecs_capacity_provider" "ecs_cp" {
  name = "stockwiz-${var.environment}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn
  }
}

# -----------------------------
# Associate provider with cluster
# -----------------------------
resource "aws_ecs_cluster_capacity_providers" "ecs_cp_assoc" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_cp.name]
}
