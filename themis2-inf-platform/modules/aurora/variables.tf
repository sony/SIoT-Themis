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

variable "max_capacity" {
  type        = number
  description = "Aurora 容量ユニットの最小キャパシティ"
}

variable "min_capacity" {
  type        = number
  description = "Aurora 容量ユニットの最大キャパシティ"
}

variable "engine_version" {
  type        = string
  description = "PostgreSQLエンジンバージョン"
}

variable "master_username" {
  type        = string
  description = "データベースのユーザー名"
}

variable "master_password" {
  type        = string
  description = "データベースのパスワード"
  sensitive   = true
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR address range of VPC"
}
