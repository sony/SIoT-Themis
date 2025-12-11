output "docdb_data_controller_api_url" {
  value = module.ecr.docdb_data_controller_api_url
}

output "docdb_realtime_notification_api_url" {
  value = module.ecr.docdb_realtime_notification_api_url
}

output "cygnus_docdb_endpoint" {
  value = module.cygnus_docdb.docdb_endpoint
}

output "aurora_db_endpoint" {
  value = module.aurora_db.aurora_endpoint
}

output "eks_cluster_name" {
  value = module.eks["infra"].cluster_name
}

output "aws_iot_certificate_id" {
  value = module.iot_core.certificate_id
}
