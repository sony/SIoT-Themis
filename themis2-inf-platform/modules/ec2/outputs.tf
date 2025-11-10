output "ec2_eip_address" {
  description = "EC2 インスタンスに割り当てられた Elastic IP アドレス"
  value = aws_eip.this.public_ip
}
