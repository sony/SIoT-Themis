variable "sys_name" {
  description = "system naming prefix"
  type        = string
}

variable "env" {
  type        = string
  description = "Specify environment name"
}

#canary value

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
