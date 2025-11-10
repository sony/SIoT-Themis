
# タグ名パターンに基づいてNAT GatewayのIPを取得
data "aws_nat_gateways" "servicer_nat_gateways" {
  filter {
    name   = "tag:Name"
    values = ["${var.sys_name}-${var.env}-servicer-nat-*"]
  }
}

# 個々のNAT Gatewayの詳細を取得
data "aws_nat_gateway" "servicer_nat_gateways" {
  for_each = toset(data.aws_nat_gateways.servicer_nat_gateways.ids)
  id       = each.value
}

# NAT GatewayのIPアドレスをCIDR形式のリストで作成
locals {
  servicer_nat_gateway_cidr_blocks = [
    for nat_gw in data.aws_nat_gateway.servicer_nat_gateways : 
    "${nat_gw.public_ip}/32"
  ]
}

# タグ名パターンに基づいてEC2インスタンスのIPを取得
data "aws_instances" "servicer_ec2" {
  filter {
    name   = "tag:Name"
    values = ["${var.sys_name}-${var.env}-servicer-ec2-iac"]
  }
}

# servicer EC2インスタンスのパブリックIPを取得
locals {
  servicer_ec2_ip = length(data.aws_instances.servicer_ec2.public_ips) > 0 ? data.aws_instances.servicer_ec2.public_ips[0] : null
}

# waf 構成
resource "aws_wafv2_ip_set" "this" {
  name               = "${var.sys_name}-${var.env}-ipset-admins"
  description        = "Administrators IP set"
  scope              = "CLOUDFRONT"
  provider           = aws.virginia
  ip_address_version = "IPV4"
  addresses          = var.admin_cidr_blocks

  tags = {
    Name = "${var.sys_name}-${var.env}-ipset-admins"
  }
}

resource "aws_wafv2_ip_set" "transformation_ips" {
  name               = "${var.sys_name}-${var.env}-ipset-transformation"
  description        = "Allowed IPs for ${var.env}-transformation domains"
  scope              = "CLOUDFRONT"
  provider           = aws.virginia
  ip_address_version = "IPV4"

  addresses = [for ip in var.allowed_ips : "${ip}/32"]

  tags = {
    Name = "${var.sys_name}-${var.env}-ipset-transformation"
  }
}

resource "aws_wafv2_regex_pattern_set" "urlnames" {
  name     = "${var.sys_name}-${var.env}-urlnames"
  scope    = "CLOUDFRONT"
  provider = aws.virginia

  regular_expression {
    regex_string = "${var.env}-platform\\.unvs-themis\\.com"
  }

  regular_expression {
    regex_string = "${var.env}-iotagent\\.unvs-themis\\.com"
  }
}

resource "aws_wafv2_regex_pattern_set" "transformation_domains" {
  name     = "${var.sys_name}-${var.env}-regexset-transformation"
  scope    = "CLOUDFRONT"
  provider = aws.virginia

  regular_expression {
    regex_string = "${var.env}-transformation\\.unvs-themis\\.com"
  }

  regular_expression {
    regex_string = "${var.env}-transformation2\\.unvs-themis\\.com"
  }
}

resource "aws_wafv2_ip_set" "servicer_nat_gw" {
  provider           = aws.virginia
  name               = "${var.sys_name}-${var.env}-servicer-nat-gw-ipset"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses = concat(
    local.servicer_nat_gateway_cidr_blocks,
    local.servicer_ec2_ip != null ? ["${local.servicer_ec2_ip}/32"] : []
  )

  description = "IP set for servicer NAT gateway CIDR blocks and IaC server access IP"
}

resource "aws_wafv2_web_acl" "cloudfront_waf_web_acl" {
  name        = "${var.sys_name}-${var.env}-waf"
  description = "Web ACL for themis2 ${var.env} environment"
  scope       = "CLOUDFRONT"
  provider    = aws.virginia

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = var.cloudwatch_metrics_value
    metric_name                = "${var.sys_name}-${var.env}-waf"
    sampled_requests_enabled   = var.sampled_requests_value
  }

  rule {
    name     = "${var.sys_name}-${var.env}-custom-rule-AllowIPsForConsoles"
    priority = 10

    action {
      allow {}
    }

    statement {
      and_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.this.arn
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.urlnames.arn
            field_to_match {
              single_header {
                name = "host"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "${var.sys_name}-${var.env}-waf-AllowIPsForConsoles"
      sampled_requests_enabled = true
    }
  }

  rule {
    name     = "${var.sys_name}-${var.env}-custom-rule-BlockConsolesForOthers"
    priority = 20

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.urlnames.arn
        field_to_match {
          single_header {
            name = "host"
          }
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name = "${var.sys_name}-${var.env}-waf-BlockConsolesForOthers"
      sampled_requests_enabled = true
    }
  }

  rule {
    name     = "${var.sys_name}-${var.env}-waf-AWSManagedRulesCommonRuleSet-Override"
    priority = 30

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        scope_down_statement {
          or_statement {
            statement {
              regex_match_statement {
                regex_string = var.grafana_domain_regex
                field_to_match {
                  single_header {
                    name = "host"
                  }
                }
                text_transformation {
                  priority = 0
                  type     = "NONE"
                }
              }
            }
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.servicer_nat_gw.arn
              }
            }
          }
        }

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_value
      metric_name                = "${var.sys_name}-${var.env}-waf-AWSManagedRulesCommonRuleSet-Override"
      sampled_requests_enabled   = var.sampled_requests_value
    }
  }

  rule {
    name     = "${var.sys_name}-${var.env}-waf-AWSManagedRulesCommonRuleSet-ExcludeGrafanaAndServicer"
    priority = 31

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        
        scope_down_statement {
          not_statement {
            statement {
              or_statement {
                statement {
                  regex_match_statement {
                    regex_string = var.grafana_domain_regex
                    field_to_match {
                      single_header {
                        name = "host"
                      }
                    }
                    text_transformation {
                      priority = 0
                      type     = "NONE"
                    }
                  }
                }
                statement {
                  ip_set_reference_statement {
                    arn = aws_wafv2_ip_set.servicer_nat_gw.arn
                  }
                }
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_value
      metric_name                = "${var.sys_name}-${var.env}-waf-AWSManagedRulesCommonRuleSet-ExcludeGrafanaAndServicer"
      sampled_requests_enabled   = var.sampled_requests_value
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAdminProtectionRuleSet"
    priority = 40

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"
        scope_down_statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.this.arn
              }
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_value
      metric_name                = "${var.sys_name}-${var.env}-waf-AWSManagedRulesAdminProtectionRuleSet"
      sampled_requests_enabled   = var.sampled_requests_value
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 50

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_value
      metric_name                = "${var.sys_name}-${var.env}-waf-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = var.sampled_requests_value
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 60

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_value
      metric_name                = "${var.sys_name}-${var.env}-waf-AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = var.sampled_requests_value
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesLinuxRuleSet"
    priority = 70

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_value
      metric_name                = "${var.sys_name}-${var.env}-waf-AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled   = var.sampled_requests_value
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 80

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_value
      metric_name                = "${var.sys_name}-${var.env}-waf-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = var.sampled_requests_value
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesAnonymousIpList"
    priority = 90

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = var.cloudwatch_metrics_value
      metric_name                = "${var.sys_name}-${var.env}-waf-AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = var.sampled_requests_value
    }
  }
  rule {
    name     = "${var.sys_name}-${var.env}-AllowIPsForTransformation"
    priority = 100

    action {
      allow {}
    }

    statement {
      and_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.transformation_ips.arn
          }
        }
        statement {
          regex_pattern_set_reference_statement {
            arn = aws_wafv2_regex_pattern_set.transformation_domains.arn
            field_to_match {
              single_header {
                name = "host"
              }
            }
            text_transformation {
              priority = 0
              type     = "NONE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.sys_name}-${var.env}-AllowIPsForTransformation"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "${var.sys_name}-${var.env}-BlockOthersForTransformation"
    priority = 110

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.transformation_domains.arn
        field_to_match {
          single_header {
            name = "host"
          }
        }
        text_transformation {
          priority = 0
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.sys_name}-${var.env}-BlockOthersForTransformation"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_logging_configuration" "cloudfront_waf_web_acl_log" {
  log_destination_configs = [aws_s3_bucket.waf_logging.arn]
  provider                = aws.virginia
  resource_arn            = aws_wafv2_web_acl.cloudfront_waf_web_acl.arn
}

# waf logging

resource "aws_s3_bucket" "waf_logging" {
  bucket        = "aws-waf-logs-${var.sys_name}-${var.env}-s3-waf-log"
  force_destroy = true

  tags = {
    Name = "${var.sys_name}-${var.env}-s3-waf-log"
  }
}

resource "aws_s3_bucket_public_access_block" "waf_logging" {
  bucket = aws_s3_bucket.waf_logging.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logging" {
  bucket = aws_s3_bucket.waf_logging.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "waf_logging" {
  bucket = aws_s3_bucket.waf_logging.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logging" {
  bucket = aws_s3_bucket.waf_logging.id
  rule {
    id = "${var.sys_name}-${var.env}-s3-waf-log-lifecycle-rule"
    expiration {
      days = var.waf_log_expiration_days
    }
    status = "Enabled"
  }
}
