resource "aws_s3_bucket" "alb_logging" {
  bucket        = "${var.sys_name}-${var.env}-s3-servicer-alb-accesslog"
  force_destroy = true

  tags = {
    Name = "${var.sys_name}-${var.env}-s3-servicer-alb-accesslog"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logging" {
  bucket = aws_s3_bucket.alb_logging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logging" {
  bucket = aws_s3_bucket.alb_logging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "alb_logging" {
  bucket = aws_s3_bucket.alb_logging.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "alb_logging" {
  bucket = aws_s3_bucket.alb_logging.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "logdelivery.elasticloadbalancing.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.sys_name}-${var.env}-s3-servicer-alb-accesslog/*"
      }
    ]
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logging" {
  bucket = aws_s3_bucket.alb_logging.id
  rule {
    id = "${var.sys_name}-${var.env}-s3-servicer-alb-accesslog-lifecycle-rule"
    expiration {
      days = var.s3_alb_accesslog_expiration_days
    }
    status = "Enabled"
  }
}
