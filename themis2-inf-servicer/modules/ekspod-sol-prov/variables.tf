#common value

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "cluster_identifier_sol_prov" {
  type        = string
  description = "クラスター識別用"
}

variable "sys_name" {
  description = "system naming prefix"
  type        = string
}

variable "env" {
  type        = string
  description = "Specify environment name"
}

variable "sample_analyzer_tg_arn" {
  type        = string
  description = "target group bind arn"
}

variable "sample_tracker_tg_arn" {
  type        = string
  description = "target group bind arn"
}

variable "grafana_tg_arn" {
  type        = string
  description = "target group bind arn"
}

variable "transformation_tg_arn" {
  type        = string
  description = "target group bind arn"
}

variable "keycloak2_tg_arn" {
  type        = string
  description = "target group bind arn"
}

variable "servicer_console_tg_arn" {
  type        = string
  description = "target group bind arn"
}

variable "alb_api_domains" {
  type        = map(string)
  description = "ALB ホスト名のドメイン一覧"
}

variable "sample_tracker_backend_api_key" {
  type        = string
  description = "サンプル可視化サービス（トラッカー）向けバックエンドAPIキー"
  sensitive   = true
}

variable "bacth_analyzer_data_controller_api_key" {
  type        = string
  description = "プラットフォーム管理コンソールで作成したdata controller api key"
  sensitive   = true
}

variable "batch_analyzer_key_command" {
  type        = string
  description = "batch analyzerのコマンドキー"
}

variable "servicer_console_keycloak_client_id" {
  type        = string
  description = "サービサー管理コンソール向けKeyclaokクライアントID"
}

variable "servicer_console_keycloak_client_secret" {
  type        = string
  description = "サービサー管理コンソール向けKeyclaokクライアントのシークレット"
  sensitive   = true
}

variable "ecr_servicer_console_url" {
  type        = string
  description = "サービサー管理コンソール用ECRのURL"
}

variable "ecr_grafana_url" {
  type        = string
  description = "ECR Grafana URL"
}

variable "cluster_autoscaler_version" {
  type        = string
  default     = null
  description = "Cluster Autoscalerのバージョン"
}

variable "data_filtering_api_backend_api_key" {
  type        = string
  description = "プラットフォーム管理コンソールで作成したdata filtering api key"
  sensitive   = true
}

variable "ecr_data_filtering_api_url" {
  type        = string
  description = "データフィルタリングAPI用ECRのURL"
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

variable "eks_data_plane_subnet_cidr_blocks" {
  type        = map(string)
  description = "CIDR blocks used for the EKS data plane"
}

variable "iac_subnet_cidr_block" {
  type        = string
  description = "CIDR block of the subnet used by EC2 instances"
}

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

variable "keycloak_setting_client_root_url" {
  type        = string
  description = "Keycloakクライアント ルートURL"
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

variable "postgres_setting_ecr_url" {
  type        = string
  description = "orion-settingsのECRイメージURL"
}

variable "realtime_notification_api_key" {
  type        = string
  description = "realtime notification API key"
}

variable "domain" {
  type        = string
  description = "Domain name for API endpoints"
}
