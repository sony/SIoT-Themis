locals {
  source_hash = data.local_file.canary_source.content_sha256
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "local_file" "canary_source" {
  filename = "${path.module}/canary_scripts/source/nodejs/node_modules/pageLoadBlueprint.js"
}

data "archive_file" "canary_zip" {
  type        = "zip"
  source_dir  = "${path.module}/canary_scripts/source"
  output_path = "${path.module}/canary_scripts/synthetics_${local.source_hash}.zip"
}

data "aws_iam_policy_document" "canary_lambda" {

  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.s3_canary.arn}/canary/*"
    ]
  }

  statement {
    actions = [
      "s3:GetBucketLocation"
    ]
    resources = [
      aws_s3_bucket.s3_canary.arn
    ]
  }

  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/cwsyn-${aws_synthetics_canary.canary.id}-*"
    ]
  }

  statement {
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = [
      "arn:aws:s3:::*"
    ]
  }

  statement {
    actions = [
      "cloudwatch:PutMetricData"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEquals"
      variable = "cloudwatch:namespace"

      values = ["CloudWatchSynthetics"]
    }
  }
}

resource "aws_iam_policy" "canary_lambda" {
  name   = "${var.sys_name}-${var.env}-canary-policy"
  policy = data.aws_iam_policy_document.canary_lambda.json
}

data "aws_iam_policy" "canary_policy" {
  arn = "arn:aws:iam::aws:policy/CloudWatchSyntheticsFullAccess"
}

resource "aws_iam_role" "canary_role" {
  name = "${var.sys_name}-${var.env}-canary-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "canary_role" {
  role       = aws_iam_role.canary_role.name
  policy_arn = data.aws_iam_policy.canary_policy.arn
}

resource "aws_iam_role_policy_attachment" "canary_lambda_role" {
  role       = aws_iam_role.canary_role.name
  policy_arn = aws_iam_policy.canary_lambda.arn
}

# canary
resource "aws_synthetics_canary" "canary" {
  name                     = "${var.sys_name}-${var.env}-visualize-tracker-monitoring"
  delete_lambda            = true
  start_canary             = var.start_canary
  artifact_s3_location     = "s3://${aws_s3_bucket.s3_canary.bucket}/canary/"
  execution_role_arn       = aws_iam_role.canary_role.arn
  handler                  = "pageLoadBlueprint.handler"
  zip_file                 = data.archive_file.canary_zip.output_path
  runtime_version          = var.canary_runtime_version
  success_retention_period = var.canary_success_retention_period
  failure_retention_period = var.canary_failure_retention_period

  schedule {
    expression = "rate(${var.rate_minutes} hour)"
  }

  run_config {
    timeout_in_seconds = 60
    memory_in_mb       = 1024
  }
}

# Canary S3

resource "aws_s3_bucket" "s3_canary" {
  bucket        = "${var.sys_name}-${var.env}-visualize-tracker-canary-results"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_canary" {
  bucket = aws_s3_bucket.s3_canary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_canary" {
  bucket = aws_s3_bucket.s3_canary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "s3_canary" {
  bucket = aws_s3_bucket.s3_canary.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_canary" {
  bucket = aws_s3_bucket.s3_canary.id

  rule {
    id = "${var.sys_name}-${var.env}-canary-log-lifecycle-rule"

    status = "Enabled"

    expiration {
      days = var.s3_canary_log_expiration_days
    }
  }
}
