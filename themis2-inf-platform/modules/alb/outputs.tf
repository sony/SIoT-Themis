# cloudfront用ALB arn
output "alb_arn" {
  value = aws_lb.themis2_alb.arn
}

# target group bind用
output "iotagent_tg_arn" {
  value = aws_lb_target_group.iotagent_tg.arn
}

output "keycloak_tg_arn" {
  value = aws_lb_target_group.keycloak_tg.arn
}

output "platform_console_tg_arn" {
  value = aws_lb_target_group.platform_console_tg.arn
}

output "external_kong_tg_arn" {
  value = aws_lb_target_group.external_kong_tg.arn
}

output "iotagent_json_tg_arn" {
  value = aws_lb_target_group.iotagent_json_tg.arn
}
