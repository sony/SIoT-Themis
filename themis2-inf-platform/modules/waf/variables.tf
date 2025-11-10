variable "sys_name" {
  description = "system naming prefix"
  type        = string
}

variable "env" {
  type        = string
  description = "Specify environment name"
}

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

variable "admin_cidr_blocks" {
  type        = list(string)
  description = "管理者のネットワークアドレス一覧"
}

variable "allowed_ips" {
  type        = list(string)
  description = "WAF IPSet に登録する許可された IP アドレス（Elastic IP など）"
}

# Grafanaドメインの正規表現パターン
variable "grafana_domain_regex" {
  description = "Regular expression pattern for Grafana domains"
  type        = string
}
