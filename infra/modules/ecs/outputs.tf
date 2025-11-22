output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_asg_name" {
  value = aws_autoscaling_group.ecs_asg.name
}

output "ecs_capacity_provider_name" {
  value = aws_ecs_capacity_provider.ecs_cp.name
}

output "launch_template_id" {
  value = aws_launch_template.ecs_lt.id
}

output "ecs_asg_arn" {
  value = aws_autoscaling_group.ecs_asg.arn
}