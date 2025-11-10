# ECR Scaning Configuration
resource "aws_ecr_registry_scanning_configuration" "configuration" {
  count     = var.is_fresh_deployment ? 1 : 0
  scan_type = "BASIC"

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = "*"
      filter_type = "WILDCARD"
    }
  }
}

# ECR Repository
resource "aws_ecr_repository" "data_controller_api" {
  name                 = "${var.sys_name}/data-controller-api/${var.env}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

resource "aws_ecr_repository" "realtime_notification_api" {
  name                 = "${var.sys_name}/realtime-notification-api/${var.env}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

resource "aws_ecr_repository" "platform_console" {
  name                 = "${var.sys_name}/platform-console/${var.env}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

resource "aws_ecr_repository" "eltres_agent" {
  name                 = "${var.ns_option_value}/eltres-agent/${var.env}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

resource "aws_ecr_repository" "eltres_console" {
  name                 = "${var.ns_option_value}/eltres-console/${var.env}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

resource "aws_ecr_repository" "cygnus" {
  name                 = "${var.ns_infra_value}/cygnus/${var.env}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

resource "aws_ecr_repository" "docdb_data_controller_api" {
  name                 = "${var.sys_name}/docdb-data-controller-api/${var.env}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

resource "aws_ecr_repository" "docdb_realtime_notification_api" {
  name                 = "${var.sys_name}/docdb-realtime-notification-api/${var.env}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

resource "aws_ecr_repository" "kong_setting" {
  name                 = "${var.sys_name}/kong-setting/${var.env}"
  image_tag_mutability = var.image_tag_mutability
}

resource "aws_ecr_repository" "postgres_setting" {
  name                 = "${var.sys_name}/postgres-setting/${var.env}"
  image_tag_mutability = var.image_tag_mutability
}
