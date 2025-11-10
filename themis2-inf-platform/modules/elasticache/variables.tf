variable "sys_name" {
  type        = string
  description = "システム名"
}

variable "env" {
  type        = string
  description = "環境名"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "eks_cluster_identifier" {
  type        = string
  description = "クラスター識別子"
}

variable "eks_dataplane_subnet_ids" {
  type        = list(string)
  description = "EKS dataplaneサブネットID"
}

variable "eks_node_security_group_id" {
  type        = string
  description = "EKS nodeセキュリティグループID"
}

variable "elasticache_major_engine_version" {
  type        = string
  description = "ElastiCacheのエンジンバージョン"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR address range of VPC"
}
