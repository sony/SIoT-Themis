#Output Repository url
output "realtime_analyzer_url" {
  value = aws_ecr_repository.realtime_analyzer.repository_url
}

output "batch_analyzer_url" {
  value = aws_ecr_repository.batch_analyzer.repository_url
}

output "visualize_tracker_url" {
  value = aws_ecr_repository.visualize_tracker.repository_url
}

output "ecr_servicer_console1_url" {
  value       = aws_ecr_repository.servicer_console1.repository_url
}

output "ecr_servicer_console2_url" {
  value       = aws_ecr_repository.servicer_console2.repository_url
}

output "grafana_url" {
  value = aws_ecr_repository.grafana.repository_url
}

output "ecr_data_filtering_api_url" {
  value = aws_ecr_repository.data-filtering-api.repository_url
}

output "postgres_setting_url" {
  value = aws_ecr_repository.postgres_setting.repository_url
}
