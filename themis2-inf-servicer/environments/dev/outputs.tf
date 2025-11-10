output "sol_prov_eks_cluster_name" {
  value = module.eks["sol_prov"].cluster_name
}

output "sol_prov2_eks_cluster_name" {
  value = module.eks["sol_prov2"].cluster_name
}

output "ecr_servicer_console1_url" {
  value = module.ecr.ecr_servicer_console1_url
}

output "ecr_servicer_console2_url" {
  value = module.ecr.ecr_servicer_console2_url
}

output "grafana_url" {
  value = module.ecr.grafana_url
}

output "ecr_data_filtering_api_url" {
  value = module.ecr.ecr_data_filtering_api_url
}
