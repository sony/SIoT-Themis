data "aws_cloudfront_cache_policy" "cache_pol" {
  # CachingOptimized のAWSマネージドキャッシュポリシーを適応
  # https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html?icmpid=docs_cf_help_panel#managed-cache-policy-caching-disabled
  id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}

data "aws_cloudfront_origin_request_policy" "origin_req_pol" {
  # CORS-S3Origin のAWSマネージドオリジンリクエストポリシーを適応
  # https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/using-managed-origin-request-policies.html#managed-origin-request-policy-all-viewer
  id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
}

data "aws_wafv2_web_acl" "cloudfront_waf_web_acl" {
  name     = "${var.sys_name}-${var.env}-waf"
  scope    = "CLOUDFRONT"
  provider = aws.virginia
}

data "aws_lb" "alb" {
  arn = var.alb_arn
}

data "aws_acm_certificate" "cloudfront_public" {
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
  provider    = aws.virginia
}

resource "aws_cloudfront_distribution" "cf_themis2" {
  provider = aws.virginia

  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for ${var.env}-${var.domain_name} (servicer)"

  aliases = var.aliase_domains

  origin {
    domain_name = data.aws_lb.alb.dns_name
    origin_id   = "${var.sys_name}-${var.env}-servicer-alb"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id = "${var.sys_name}-${var.env}-servicer-alb"

    compress               = false
    viewer_protocol_policy = "https-only"

    allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.cache_pol.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.origin_req_pol.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.cloudfront_public.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  logging_config {
    include_cookies = true
    bucket          = aws_s3_bucket.cloudfront_logging.bucket_domain_name
    prefix          = var.cloudfront_log_prefix
  }
  web_acl_id = data.aws_wafv2_web_acl.cloudfront_waf_web_acl.arn
}

# Cloudfront access log用 S3 Bucket
resource "aws_s3_bucket" "cloudfront_logging" {
  bucket        = "${var.sys_name}-${var.env}-servicer-cf-log"
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logging" {
  bucket = aws_s3_bucket.cloudfront_logging.id

  rule {
    id = "${var.sys_name}-${var.env}-servicer-cf-log-lifecycle-rule"

    status = "Enabled"

    expiration {
      days = var.cloudfront_log_expiration_days
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logging" {
  bucket = aws_s3_bucket.cloudfront_logging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logging" {
  bucket = aws_s3_bucket.cloudfront_logging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudfront_logging" {
  bucket = aws_s3_bucket.cloudfront_logging.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logging" {
  bucket = aws_s3_bucket.cloudfront_logging.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logging" {
  bucket = aws_s3_bucket.cloudfront_logging.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.cloudfront_logging]
}

data "aws_route53_zone" "selected" {
  name = var.domain_name
}

resource "aws_route53_record" "this" {
  for_each = toset(var.aliase_domains)

  zone_id = data.aws_route53_zone.selected.zone_id
  name    = replace(each.value, ".${var.domain_name}", "")
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cf_themis2.domain_name
    zone_id                = aws_cloudfront_distribution.cf_themis2.hosted_zone_id
    evaluate_target_health = true
  }
}
