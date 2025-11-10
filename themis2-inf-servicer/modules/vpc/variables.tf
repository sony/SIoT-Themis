variable "sys_name" {
  type        = string
  description = "Specify system name"
}

variable "env" {
  type        = string
  description = "Specify environment name"
}

variable "region" {
  type        = string
  description = "Specify the region to use"
}

variable "availability_zones" {
  type        = map(string)
  description = "Specify availability zones"
}

variable "cidr_block" {
  type        = string
  description = "CIDR address range of VPC"
}

variable "eks_data_plane_subnet_cidr_blocks" {
  type        = map(string)
  description = "EKSデータプレーン用プライベートサブネットCidr Blocks"
}

variable "eks_control_plane_subnet_cidr_blocks" {
  type        = map(string)
  description = "EKSコントロールプレーン用プライベートサブネットCidr Blocks"
}

variable "iac_subnet_cidr_block" {
  type        = string
  description = "IaC展開サーバー用パブリックサブネットCidr Blocks"
}

variable "eks_ingress_subnet_cidr_blocks" {
  type        = map(string)
  description = "EKS Ingress及びNAT Gateway用パブリックサブネットCidr Blocks"
}

# 許可するCIDRリスト
variable "allowed_cidr_blocks" {
  description = "List of allowed CIDR blocks"
  type        = list(string)
}

# 許可するTCPポートのリスト
variable "tcp_ports" {
  description = "Allowed TCP port and security group rule number list"
  type        = map(number)
  default     = {
    443 = 0
    22  = 10
    80  = 20
    53  = 30
  }
}

# 許可するUDPポートのリスト
variable "udp_ports" {
  description = "Allowed UDP port and security group rule number list"
  type        = map(number)
  default     = {
    53 = 0
  }
}
