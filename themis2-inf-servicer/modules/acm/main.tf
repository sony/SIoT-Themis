# Route53 ドメイン情報呼び出し
data "aws_route53_zone" "domain_zone" {
  name         = var.domain_name
  private_zone = false
}

# ACM パブリック証明書登録(Cloudfront用)
resource "aws_acm_certificate" "cloudfront_public" {
  provider = aws.virginia

  domain_name               = data.aws_route53_zone.domain_zone.name
  subject_alternative_names = ["*.${data.aws_route53_zone.domain_zone.name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 Cloudfront DNS検証
resource "aws_route53_record" "cloudfront_public_dns_verify" {
  for_each = {
    for dvo in aws_acm_certificate.cloudfront_public.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.domain_zone.id
}

resource "aws_acm_certificate_validation" "cloudfront_public" {
  provider = aws.virginia

  certificate_arn         = aws_acm_certificate.cloudfront_public.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_public_dns_verify : record.fqdn]
}

# ACM パブリック証明書登録(ALB用)
resource "aws_acm_certificate" "alb_public" {
  domain_name               = data.aws_route53_zone.domain_zone.name
  subject_alternative_names = ["*.${data.aws_route53_zone.domain_zone.name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 ALB DNS検証
resource "aws_route53_record" "alb_public_dns_verify" {
  for_each = {
    for dvo in aws_acm_certificate.alb_public.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.domain_zone.id
}

resource "aws_acm_certificate_validation" "alb_public" {
  certificate_arn         = aws_acm_certificate.alb_public.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_public_dns_verify : record.fqdn]
}
