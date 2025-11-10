# Common Cloudfront Value
variable "sys_name" {
  description = "system naming prefix"
  type        = string
}

variable "env" {
  type        = string
  description = "Specify environment name"
}

variable "domain_name" {
  type        = string
  description = "domain name"
}

variable "cloudfront_log_prefix" {
  type        = string
  description = "ログプレフィックス"
}

variable "cloudfront_log_expiration_days" {
  type        = number
  description = "オブジェクト有効期限"
}

variable "aliase_domains" {
  type        = list(string)
  description = "エイリアスに設定するドメイン一覧"
}

variable "alb_arn" {
  type        = string
  description = "Application load balancerのARN"
}
