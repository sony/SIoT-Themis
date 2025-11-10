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
resource "aws_ecr_repository" "realtime_analyzer" {
  name                 = "${var.ns_sample_value}/realtime-analyzer/${var.env}"
  image_tag_mutability = var.image_tag_mutability
}

resource "aws_ecr_repository" "batch_analyzer" {
  name                 = "${var.ns_sample_value}/batch-analyzer/${var.env}"
  image_tag_mutability = var.image_tag_mutability
}

resource "aws_ecr_repository" "visualize_tracker" {
  name                 = "${var.ns_sample_value}/visualize-tracker/${var.env}"
  image_tag_mutability = var.image_tag_mutability
}

resource "aws_ecr_repository" "realtime-transformation-api" {
  name                 = "${var.ns_sample_value}/realtime-transformation-api/${var.env}"
  image_tag_mutability = var.image_tag_mutability
}

resource "aws_ecr_repository" "grafana" {
  name                 = "${var.ns_sample_value}/grafana/${var.env}"
  image_tag_mutability = var.image_tag_mutability
}

resource "aws_ecr_repository" "servicer_console1" {
  name                 = "${var.ns_sample_value}/servicer-console1/${var.env}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

resource "aws_ecr_repository" "servicer_console2" {
  name                 = "${var.ns_sample_value}/servicer-console2/${var.env}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = true
}

resource "aws_ecr_repository" "data-filtering-api" {
  name                 = "${var.ns_sample_value}/data-filtering-api/${var.env}"
  image_tag_mutability = var.image_tag_mutability
}

resource "aws_ecr_repository" "postgres_setting" {
  name                 = "${var.ns_sample_value}/postgres-setting/${var.env}"
  image_tag_mutability = var.image_tag_mutability
}
