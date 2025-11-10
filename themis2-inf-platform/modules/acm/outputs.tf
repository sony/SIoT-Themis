output "cloudfront_crt_arn" {
  value = aws_acm_certificate.cloudfront_public.arn
}

output "alb_crt_arn" {
  value = aws_acm_certificate.alb_public.arn
}
