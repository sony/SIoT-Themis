#common value

variable "cluster_identifier_infra" {
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

variable "iotagent_tg_arn" {
  type        = string
  description = "target group bind arn"
}

variable "keycloak_tg_arn" {
  type        = string
  description = "target group bind arn"
}

variable "platform_console_tg_arn" {
  type        = string
  description = "target group bind arn"
}

variable "external_kong_tg_arn" {
  type        = string
  description = "target group bind arn"
}

variable "alb_api_domains" {
  type        = map(string)
  description = "ALB ホスト名のドメイン一覧"
}

variable "platform_console_keycloak_client_id" {
  type        = string
  description = "プラットフォーム管理コンソール向けKeyclaokクライアントID"
}

variable "platform_console_keycloak_client_secret" {
  type        = string
  description = "プラットフォーム管理コンソール向けKeyclaokクライアントのシークレット"
  sensitive   = true
}

variable "iotagent_console_keycloak_client_secret" {
  type        = string
  description = "IoTエージェント管理コンソール向けKeyclaokクライアントのシークレット"
  sensitive   = true
}

variable "orion_docdb_master_username" {
  type        = string
  description = "Orion DocumentDBのユーザ名"
}

variable "orion_docdb_master_password" {
  type        = string
  description = "Orion DocumentDBのパスワード"
  sensitive   = true
}

variable "orion_docdb_endpoint" {
  type = string
}

variable "orion_docdb_port" {
  type = string
}

variable "cygnus_docdb_master_username" {
  type        = string
  description = "Cygnus DocumentDBのユーザ名"
}

variable "cygnus_docdb_master_password" {
  type        = string
  description = "Cygnus DocumentDBのパスワード"
  sensitive   = true
}

variable "cygnus_docdb_endpoint" {
  type = string
}

variable "cygnus_docdb_port" {
  type = string
}

#ecr value
variable "ns_option_value" {
  type        = string
  description = "Option用名前空間"
}

variable "ns_infra_value" {
  type        = string
  description = "インフラ用名前空間"
}

variable "mongo_ssl_truststore_password" {
  type        = string
  description = "Password for MongoDB SSL truststore"
  sensitive   = true
}

variable "ecr_docdb_data_controller_api_url" {
  type        = string
  description = "データ操作API用ECRのURL"
}

variable "aurora_db_endpoint" {
  type        = string
  description = "Aurora Serverless V2 for PostgreSQLエンドポイント"
}

variable "elasticache_endpoint" {
  type        = string
  description = "ElastiCache Serverless endpoint"
}

variable "aurora_db_master_username" {
  type        = string
  description = "Aurora Serverless V2 for PostgreSQLユーザー名"
}

variable "aurora_db_master_password" {
  type        = string
  description = "Aurora Serverless V2 for PostgreSQLパスワード"
}

variable "postgres_setting_db_name" {
  type        = string
  description = "Postgres 設定に使用されるデータベース名"
}

variable "ecr_docdb_realtime_notification_api_url" {
  type        = string
  description = "リアルタイム通知API用ECRのURL"
}

variable "eltres_agent_topics" {
  type        = string
  description = "ELTRESエージェントの用トピック"
}

variable "cluster_autoscaler_version" {
  type        = string
  default     = null
  description = "Cluster Autoscalerのバージョン"
}

variable "iotagent_json_tg_arn" {
  type        = string
  description = "target group bind arn"
}

variable "eks_data_plane_subnet_cidr_blocks" {
  type        = map(string)
  description = "CIDR blocks used for the EKS data plane"
}

variable "iac_subnet_cidr_block" {
  type        = string
  description = "CIDR block of the subnet used by EC2 instances"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR address range of VPC"
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

variable "keycloak_setting_client_root_url_platform_console" {
  type        = string
  description = "platform_consoleのKeycloakクライアント ルートURL"
}

variable "keycloak_setting_client_root_url_eltres_console" {
  type        = string
  description = "eltres_consoleのKeycloakクライアント ルートURL"
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

#ECR repository URL
variable "postgres_setting_ecr_url" {
  type        = string
  description = "postgres-settingsのECRイメージURL"
}

variable "kong_setting_ecr_url" {
  type        = string
  description = "kong-settingsのECRイメージURL"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID"
}

variable "iot_certificate_pem" {
  type        = string
  description = "IoT certificate PEM content"
  sensitive   = true
  default     = ""
}

variable "iot_private_key" {
  type        = string
  description = "IoT private key content"
  sensitive   = true
  default     = ""
}
