output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "iac_subnet" {
  description = "Subnet ID of the server for IaC deployment"
  value       = aws_subnet.public_iac.id
}

output "eks_controlplane_subnets" {
  description = "Subnet ID of EKS control planes"
  value       = [for subnet in aws_subnet.private_eks_controlplane : subnet.id]
}

output "eks_dataplane_subnets" {
  description = "Subnet ID of the EKS data planes"
  value       = [for subnet in aws_subnet.private_eks_dataplane : subnet.id]
}

output "eks_ingress_subnets" {
  description = "Subnet IDs of EKS Ingress and NAT Gateway"
  value       = [for subnet in aws_subnet.public_eks_ingress : subnet.id]
}

output "nat_gateway_eip_addresses" {
  description = "NAT Gateway に割り当てられた Elastic IP アドレスの一覧"
  value = [for eip in aws_eip.nat_gateway : eip.public_ip]
}
