#Output Repository url
output "data_controller_api_url" {
  value = aws_ecr_repository.data_controller_api.repository_url
}

output "realtime_notification_api_url" {
  value = aws_ecr_repository.realtime_notification_api.repository_url
}

output "platform_console_url" {
  value = aws_ecr_repository.platform_console.repository_url
}

output "eltres_agent_url" {
  value = aws_ecr_repository.eltres_agent.repository_url
}

output "eltres_console_url" {
  value = aws_ecr_repository.eltres_console.repository_url
}

output "docdb_data_controller_api_url" {
  value = aws_ecr_repository.docdb_data_controller_api.repository_url
}

output "docdb_realtime_notification_api_url" {
  value = aws_ecr_repository.docdb_realtime_notification_api.repository_url
}

output "kong_setting_url" {
  value = aws_ecr_repository.kong_setting.repository_url
}

output "postgres_setting_url" {
  value = aws_ecr_repository.postgres_setting.repository_url
}
