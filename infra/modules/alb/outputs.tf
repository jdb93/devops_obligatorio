output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "tg_api_arn" {
  value = aws_lb_target_group.api_tg.arn
}

output "tg_product_arn" {
  value = aws_lb_target_group.product_tg.arn
}

output "tg_inventory_arn" {
  value = aws_lb_target_group.inventory_tg.arn
}
