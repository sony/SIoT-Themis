resource "local_file" "certifycate_pem" {
  content              = aws_iot_certificate.themis2_iot_certificates.certificate_pem
  filename             = "${path.module}/certs/certificate.pem"
  directory_permission = "0777"
  file_permission      = "0777"
}

resource "local_file" "private_key_pem" {
  content              = aws_iot_certificate.themis2_iot_certificates.private_key
  filename             = "${path.module}/certs/private-key.pem"
  directory_permission = "0777"
  file_permission      = "0777"
}

resource "local_file" "public_key_pem" {
  content              = aws_iot_certificate.themis2_iot_certificates.public_key
  filename             = "${path.module}/certs/public-key.pem"
  directory_permission = "0777"
  file_permission      = "0777"
}

output "certifycate_pem" {
  value     = aws_iot_certificate.themis2_iot_certificates.certificate_pem
  sensitive = true
}

output "private_key_pem" {
  value     = aws_iot_certificate.themis2_iot_certificates.private_key
  sensitive = true
}

output "public_key_pem" {
  value     = aws_iot_certificate.themis2_iot_certificates.public_key
  sensitive = true
}
