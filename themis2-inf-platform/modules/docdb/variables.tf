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

variable "docdb_cluster_identifier" {
  type        = string
  description = "DocumentDBクラスタ識別子"
}

variable "docdb_engine_version" {
  type        = string
  description = "DocumentDBエンジンのバージョン"
}

variable "docdb_master_username" {
  type        = string
  description = "DocumentDBのユーザー名"
}

variable "docdb_master_password" {
  sensitive   = true
  type        = string
  description = "DocumentDBのパスワード"
}

variable "docdb_preferred_backup_window" {
  type        = string
  description = "DocumentDB推奨バックアップウィンドウ"
}

variable "docdb_instance_class" {
  type        = string
  description = "DocumentDBインスタンスクラス"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR address range of VPC"
}
