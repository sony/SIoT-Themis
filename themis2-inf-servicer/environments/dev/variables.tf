#common value

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "sys_name" {
  description = "system naming prefix"
  type        = string
}

variable "env" {
  type        = string
  description = "Specify environment name"
}

variable "use_region" {
  type        = string
  description = "Specify the region to use"
}

variable "availability_zones" {
  type        = map(string)
  description = "Specify availability zones"
}

variable "cluster_identifier" {
  type        = map(string)
  description = "サービサー用クラスター識別子"
}

#vpc value

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

# EC2 (IaCサーバー)
variable "iac_ami_id" {
  type        = string
  description = "サービサー用IaC展開サーバーのAMI ID"
}

variable "iac_instance_type" {
  type        = string
  description = "IaC展開サーバーのインスタンスタイプ"
}

variable "iac_allow_cidr_blocks" {
  type        = set(string)
  description = "IaC展開サーバーへの接続を許可するネットワーク (CIDR表記)"
}

variable "iac_ssh_port_number" {
  type        = number
  description = "IaC展開サーバーのSSHポート番号"
}

variable "iac_root_volume_size" {
  type        = number
  description = "IaC展開サーバーのルートボリュームサイズ (GB)"
}

variable "iac_root_volume_type" {
  type        = string
  description = "IaC展開サーバーのルートボリュームの種類 (GP2, GP3など)"
}

variable "iac_root_volume_iops" {
  type        = number
  description = "IaC展開サーバーのルートボリュームのIOPS (GP3向け)"
}

variable "iac_root_volume_throughput" {
  type        = number
  description = "IaC展開サーバーのルートボリュームのスループット (GP3向け)"
}

variable "public_key_content" {
  type        = string
  description = "IaC展開サーバーのSSH接続用公開鍵の内容"
}

# EKS
variable "eks_admin_user_arns" {
  type        = set(string)
  description = "EKS クラスターの管理者 IAM ユーザー ARNs"
  validation {
    condition     = alltrue([for arn in var.eks_admin_user_arns : can(regex("^arn:aws:iam::[[:digit:]]{12}:(user|role)/[[:ascii:]]+$", arn))])
    error_message = "eks_admin_user_arns の書式が不正です。"
  }
}

variable "eks_cluster_version" {
  type        = string
  description = <<-EOT
    EKS クラスターバージョン
      https://docs.aws.amazon.com/ja_jp/eks/latest/userguide/kubernetes-versions.html"
  EOT
  validation {
    condition     = can(regex("^[[:digit:]]+.[[:digit:]]+$", var.eks_cluster_version))
    error_message = "eks_cluster_version の書式が不正です。"
  }
}

variable "eks_desired_size" {
  type        = number
  description = "EKS ノードプールの初期ノード数"
  validation {
    condition     = can(regex("^[[:digit:]]+$", var.eks_desired_size))
    error_message = "eks_desired_size の書式が不正です。整数の必要があります。"
  }
}

variable "eks_disk_size" {
  type        = number
  description = "EKS ノードのディスクサイズ"
  validation {
    condition     = can(regex("^[[:digit:]]+$", var.eks_disk_size))
    error_message = "eks_disk_size の書式が不正です。整数の必要があります。"
  }
}

variable "eks_instance_type" {
  type        = string
  description = "EKS ノードのインスタンスタイプ"
  validation {
    condition     = can(regex("^[0-9a-z-]+.[0-9a-z-]+$", var.eks_instance_type))
    error_message = "eks_instance_type の書式が不正です。"
  }
}

variable "eks_max_size" {
  type        = number
  description = "EKS ノードプールの最大ノード数"
  validation {
    condition     = can(regex("^[[:digit:]]+$", var.eks_max_size))
    error_message = "eks_disk_size の書式が不正です。整数の必要があります。"
  }
}

variable "eks_min_size" {
  type        = number
  description = "EKS ノードプールの最小ノード数"
  validation {
    condition     = can(regex("^[[:digit:]]+$", var.eks_min_size))
    error_message = "eks_disk_size の書式が不正です。整数の必要があります。"
  }
}

variable "eks_ami_id" {
  type = string
  description = "EKS ノードLaunch TemplateのAMI ID"
}

#acm value

variable "domain_name" {
  type        = string
  description = "domain name"
}

#ecr value

variable "ns_sample_value" {
  type        = string
  description = "Sample用名前空間"
}

variable "ns_option_value" {
  type        = string
  description = "Option用名前空間"
}

variable "ns_infra_value" {
  type        = string
  description = "インフラ用名前空間"
}

variable "image_tag_mutability" {
  type        = string
  description = "image tag mutability"
}

# alb value
variable "s3_alb_accesslog_expiration_days" {
  type        = number
  description = "オブジェクト有効期限"
}

variable "route53_domain_name" {
  type        = string
  description = "Route53 ドメイン名"
}

variable "alb_api_sub_domains" {
  type        = map(string)
  description = "サービサー用ALB リスナールール向けドメイン対応一覧"
}

#cloudfront value

variable "cloudfront_log_prefix" {
  type        = string
  description = "ログプレフィックス"
}

variable "cloudfront_log_expiration_days" {
  type        = number
  description = "オブジェクト有効期限"
}

### サービサー①
variable "sample_analyzer_cf" {
  type        = string
  description = "sample analyzer cf"
}

variable "sample_tracker_cf" {
  type        = string
  description = "sample tracker cf"
}
###
### サービサー①
variable "grafana_cf" {
  type        = string
  description = "grafana cf"
}

variable "transformation_cf" {
  type        = string
  description = "transformation cf"
}

variable "keycloak2_cf" {
  type        = string
  description = "keycloak2 cf"
}

variable "servicer_console_cf" {
  type        = string
  description = "servicer console cf"
}
###

### サービサー②
variable "sample_analyzer2_cf" {
  type        = string
  description = "sample analyzer2 cf"
}

variable "sample_tracker2_cf" {
  type        = string
  description = "sample tracker2 cf"
}

variable "grafana2_cf" {
  type        = string
  description = "grafana2 cf"
}

variable "transformation2_cf" {
  type        = string
  description = "transformation2 cf"
}

variable "keycloak3_cf" {
  type        = string
  description = "keycloak3 cf"
}

variable "servicer2_console_cf" {
  type        = string
  description = "servicer2 console cf"
}
###

#eks pod
## platform console
variable "sample_tracker_backend_api_key" {
  type        = string
  description = "サンプル可視化サービス（トラッカー）向けバックエンドAPIキー"
  sensitive   = true
}

## batch analyzer
variable "bacth_analyzer_data_controller_api_key" {
  type        = string
  description = "プラットフォーム管理コンソールで作成したdata controller api key"
  sensitive   = true
}

variable "batch_analyzer_key_command" {
  type        = string
  description = "batch analyzerのコマンドキー"
}

## servicer console
variable "servicer_console_keycloak_client_id" {
  type        = string
  description = "サービサー管理コンソール向けKeyclaokクライアントID"
}

variable "servicer_console_keycloak_client_secret" {
  type        = string
  description = "サービサー管理コンソール向けKeyclaokクライアントのシークレット"
  sensitive   = true
}

## canary value
variable "canary_runtime_version" {
  type        = string
  description = "canaryのruntimeバージョン"
}

variable "start_canary" {
  type        = string
  description = "canaryの起動フラグ"
}

variable "s3_canary_log_expiration_days" {
  type        = number
  description = "オブジェクト有効期限"
}

variable "canary_failure_retention_period" {
  type        = number
  description = "canaryの失敗した実行データの保持日数"
}

variable "canary_success_retention_period" {
  type        = number
  description = "canaryの成功した実行データの保持日数"
}

variable "rate_minutes" {
  type        = number
  description = "canary実行間隔"
}

variable "is_fresh_deployment" {
  type        = bool
  description = "この環境が新規展開かどうか"
}

variable "enable_eksctl_wrapper" {
  type        = bool
  default     = true
  description = "EKSCTLラッパーを有効にするかどうか"
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

variable "eks_node_init_script" {
  type        = string
  description = "EKSのoverrideBootstrapCommandに追加するスクリプト内容"
  default     = ""
}

variable "cluster_autoscaler_version" {
  type        = string
  nullable    = false
  description = "Cluster Autoscalerのバージョン"
}

# 許可するCIDRリスト
variable "allowed_cidr_blocks" {
  description = "List of allowed CIDR blocks"
  type        = list(string)
}

## keycloak credentials
variable "keycloak_admin" {
  type        = string
  description = "Keycloak admin username"
  default     = "keycloak-admin"
}

variable "keycloak_admin_password" {
  type        = string
  description = "Keycloak admin password"
  sensitive   = true
}

## postgresql credentials
variable "postgresql_admin" {
  type        = string
  description = "PostgreSQL username"
  default     = "postgres"
}

variable "postgresql_admin_password" {
  type        = string
  description = "PostgreSQL password"
  sensitive   = true
}

## data filtering api 
variable "data_filtering_api_backend_api_key" {
  type        = string
  description = "プラットフォーム管理コンソールで作成したdata filtering api  key"
  sensitive   = true
}

variable "github_owner" {
  type        = string
  description = "GitHub repository owner/organization name"
}

variable "github_repos" {
  type        = string
  description = "A space-separated list of GitHub repository names to register the runner with"
}

variable "github_pat" {
  type        = string
  description = "GitHub Personal Access Token with runner registration permissions"
  sensitive   = true
}

# Keycloak Setting
variable "keycloak_setting_admin_username" {
  type        = string
  description = "Keycloak管理者のユーザー名"
}

variable "keycloak_setting_admin_password" {
  type        = string
  sensitive   = true
  description = "Keycloak管理者パスワード"
}

variable "keycloak_setting_new_realm" {
  type        = string
  description = "KeycloaksのRealm"
}

variable "keycloak_setting_user_username" {
  type        = string
  description = "Keycloakユーザーのユーザー名"
}

variable "keycloak_setting_user_password" {
  type        = string
  sensitive   = true
  description = "Keycloakユーザーパスワード"
}

variable "realtime_notification_api_key" {
  type        = string
  description = "realtime notification API key"
}
