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

variable "https_crt_arn" {
  type        = string
  description = "ALB certification arn"
}

variable "api_domains" {
  type        = map(string)
  description = "ALB リスナールール向けドメイン対応一覧"
}

variable "iotagent_json_cf" {
  type        = string
  description = "iotagent json cf"
}
