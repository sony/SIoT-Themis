variable "sys_name" {
  type        = string
  description = "Specify system name"
}

variable "env" {
  type        = string
  description = "Specify environment name"
}

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

variable "is_fresh_deployment" {
  type        = bool
  description = "この環境が新規展開かどうか"
}
