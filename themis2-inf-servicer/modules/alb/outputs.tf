# cloudfront用ALB arn
output "alb_arn" {
  value = aws_lb.themis2_alb.arn
}

# target group bind用
### サービサー①
output "sample_analyzer_tg_arn" {
  value = aws_lb_target_group.sample_analyzer_tg.arn
}

output "sample_tracker_tg_arn" {
  value = aws_lb_target_group.sample_tracker_tg.arn
}

output "grafana_tg_arn" {
  value = aws_lb_target_group.grafana_tg.arn
}

output "transformation_tg_arn" {
  value = aws_lb_target_group.transformation_tg.arn
}

output "keycloak2_tg_arn" {
  value = aws_lb_target_group.keycloak2_tg.arn
}
###

### サービサー②
output "sample_analyzer2_tg_arn" {
  value = aws_lb_target_group.sample_analyzer2_tg.arn
}

output "sample_tracker2_tg_arn" {
  value = aws_lb_target_group.sample_tracker2_tg.arn
}

output "grafana2_tg_arn" {
  value = aws_lb_target_group.grafana2_tg.arn
}

output "transformation2_tg_arn" {
  value = aws_lb_target_group.transformation2_tg.arn
}

output "keycloak3_tg_arn" {
  value = aws_lb_target_group.keycloak3_tg.arn
}
###

output "servicer_console_tg_arn" {
  value = aws_lb_target_group.servicer_console_tg.arn
}

output "servicer2_console_tg_arn" {
  value = aws_lb_target_group.servicer2_console_tg.arn
}
