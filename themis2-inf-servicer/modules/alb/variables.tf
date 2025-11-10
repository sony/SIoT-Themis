#common value

variable "sys_name" {
  description = "system naming prefix"
  type        = string
}

variable "env" {
  type        = string
  description = "Specify environment name"
}

variable "region" {
  type        = string
  description = "Specify the region to use"
}

variable "vpc_id" {
  type        = string
  description = "vpc id"
}

variable "s3_alb_accesslog_expiration_days" {
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

variable "grafana_cf" {
  type        = string
  description = "grafana cf"
}

variable "transformation_cf" {
  type        = string
  description = "transformation cf"
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

variable "servicer2_console_cf" {
  type        = string
  description = "servicer2 console cf"
}
###

variable "api_domains" {
  type        = map(string)
  description = "ALB リスナールール向けドメイン対応一覧"
}

### サービサー①
variable "keycloak2_cf" {
  type        = string
  description = "keycloak2 cf"
}
###

### サービサー②
variable "keycloak3_cf" {
  type        = string
  description = "keycloak3 cf"
}
###

variable "domain_name" {
  type        = string
  description = "ACM domain name"
}
