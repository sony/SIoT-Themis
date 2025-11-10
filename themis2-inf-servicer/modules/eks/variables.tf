variable "sys_name" {
  type        = string
  description = "システム名"
}

variable "env" {
  type        = string
  description = "環境名"
}

variable "region" {
  type        = string
  description = "AWS リージョン名"
}

variable "cluster_version" {
  type        = string
  description = "クラスターバージョン"
}

variable "vpc_id" {
  type        = string
  description = "クラスターが属する VPC ID"
}

variable "cluster_name" {
  type        = string
  description = "クラスター名"
}

variable "controlplane_subnet_ids" {
  type        = list(string)
  description = "クラスターが属するサブネット ID"
}

variable "dataplane_subnet_ids" {
  type        = list(string)
  description = "ノードプールが属するサブネット ID"
}

variable "ingress_subnet_ids" {
  type        = list(string)
  description = "ロードバランサーが属するサブネット ID"
}

variable "admin_user_arns" {
  type        = set(string)
  description = "EKS クラスターへのアクセスを許可するユーザー ARNs"
  nullable    = true
}

variable "ami_id" {
  type        = string
  description = "ノードプールの AMI ID"
}

variable "instance_type" {
  type        = string
  description = "ノードプールのインスタンスタイプ"
}

variable "disk_size" {
  type        = number
  description = "ノードプールのディスクサイズ（GB）"
}

variable "node_config" {
  type = object({
    min_size     = number
    max_size     = number
    desired_size = number
    update_config = object({
      max_unavailable = number
    })
  })
  description = "ノードプールのインスタンスサイズとローリングアップデートの構成"
}

variable "cluster_identifier" {
  type        = string
  description = "クラスターの識別用"
}

variable "is_fresh_deployment" {
  type        = bool
  description = "この環境が新規展開かどうか"
}

# アドオンのバージョン
variable "kube_proxy_version" {
  type        = string
  default     = null
  description = "kube-proxyのアドオンバージョン nullの場合はデフォルトバージョンが適用される"
}

variable "vpc_cni_version" {
  type        = string
  default     = null
  description = "vpc-cniのアドオンバージョン nullの場合はデフォルトバージョンが適用される"
}

variable "coredns_version" {
  type        = string
  default     = null
  description = "CoreDNSのアドオンバージョン nullの場合はデフォルトバージョンが適用される"
}

variable "init_script" {
  type        = string
  description = "EKSのoverrideBootstrapCommandに追加するスクリプト内容"
  default     = ""
}
