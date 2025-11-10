#common value

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
  description = "クラスター識別子"
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
  description = "データプラットフォーム用IaC展開サーバーのAMI ID"
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

variable "eks_node_init_script" {
  type        = string
  description = "EKSのoverrideBootstrapCommandに追加するスクリプト内容"
  default     = ""
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
  description = "ALB リスナールール向けドメイン対応一覧"
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

variable "iotagent_cf" {
  type        = string
  description = "iotagent cf"
}

variable "keycloak_cf" {
  type        = string
  description = "keycloak cf"
}

variable "platform_console_cf" {
  type        = string
  description = "platform console cf"
}

variable "external_kong_cf" {
  type        = string
  description = "external kong cf"
}

variable "iotagent_json_cf" {
  type        = string
  description = "iotagent json cf"
}
###

#waf value

variable "cloudwatch_metrics_value" {
  type        = string
  description = "cloudwatch metrics value"
}

variable "sampled_requests_value" {
  type        = string
  description = "sampled requests value"
}

variable "waf_log_expiration_days" {
  type        = number
  description = "オブジェクト有効期限"
}


#eks pod
## platform console
variable "platform_console_keycloak_client_id" {
  type        = string
  description = "プラットフォーム管理コンソール向けKeyclaokクライアントID"
}

variable "platform_console_keycloak_client_secret" {
  type        = string
  description = "プラットフォーム管理コンソール向けKeyclaokクライアントのシークレット"
  sensitive   = true
}

## iotagent console
variable "iotagent_console_keycloak_client_secret" {
  type        = string
  description = "IoTエージェント管理コンソール向けKeyclaokクライアントのシークレット"
  sensitive   = true
}
## eltres agent
variable "eltres_agent_topics" {
  type        = string
  description = "ELTRESエージェントの用トピック"
}

# DocumentDB
variable "eks_cluster_identifier" {
  type        = string
  description = "EKSクラスター識別子"
}

variable "orion_docdb_clusters" {
  type        = map(string)
  description = "Orion DocumentDBクラスタ識別子の情報"
}

variable "orion_docdb_master_password" {
  type        = string
  description = "Orion DocumentDBのパスワード"
}

variable "cygnus_docdb_clusters" {
  type        = map(string)
  description = "Cygnus DocumentDBクラスタ識別子の情報"
}

variable "cygnus_docdb_master_password" {
  type        = string
  description = "Cygnus DocumentDBのパスワード"
}

variable "docdb_engine_version" {
  type        = string
  description = "DocumentDBエンジンのバージョン"
}

variable "docdb_preferred_backup_window" {
  type        = string
  description = "DocumentDB推奨バックアップウィンドウ"
}

variable "docdb_instance_class" {
  type        = string
  description = "DocumentDBインスタンスクラス"
}

variable "mongo_ssl_truststore_password" {
  type        = string
  description = "SSL（TLS）証明書用トラストストアのパスワード "
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

# Aurora Serverless for PostgreSQL
variable "aurora_eks_cluster_identifier" {
  type        = string
  description = "EKSクラスター識別子"
}

variable "aurora_max_capacity" {
  type        = number
  description = "Aurora 容量ユニットの最小キャパシティ"
}

variable "aurora_min_capacity" {
  type        = number
  description = "Aurora 容量ユニットの最大キャパシティ"
}

variable "aurora_engine_version" {
  type        = string
  description = "PostgreSQLエンジンバージョン"
}

variable "aurora_master_username" {
  type        = string
  description = "データベースのユーザー名"
}

variable "aurora_master_password" {
  type        = string
  description = "データベースのパスワード"
  sensitive   = true
}

# ElastiCache
variable "elasticache_eks_cluster_identifier" {
  type        = string
  description = "EKSクラスター識別子"
}

variable "elasticache_major_engine_version" {
  type        = string
  description = "ElastiCacheのエンジンバージョン"
}
 
# アドオンバージョン
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

variable "cluster_autoscaler_version" {
  type        = string
  nullable    = false
  description = "Cluster Autoscalerのバージョン"
}
 
# 許可するCIDRリスト
variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of allowed CIDR blocks"
}

variable "postgres_setting_db_name" {
  type        = string
  description = "Postgres 設定に使用されるデータベース名"
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

# Grafanaドメインの正規表現パターン
variable "grafana_domain_regex" {
  description = "Regular expression pattern for Grafana domains"
  type        = string
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
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
