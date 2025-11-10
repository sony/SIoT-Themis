output "cluster_name" {
  value = "${var.sys_name}-${var.env}-eks-cp-${var.cluster_identifier}"
}

output "cluster_region" {
  value = var.region
}

output "node_group_name" {
  value = "${var.sys_name}-${var.env}-eks-dataplane-${var.cluster_identifier}"
}

output "node_security_group_id" {
  value = module.controle_plane.node_security_group_id
}
