# VPC取得
data "aws_vpc" "themis2_vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.sys_name}-${var.env}-servicer-vpc-${var.region}"]
  }
}

# ALB用セキュリティグループ作成
resource "aws_security_group" "alb_sg" {
  name        = "${var.sys_name}-${var.env}-servicer-alb-sg"
  description = "ALB Security Group"
  vpc_id      = data.aws_vpc.themis2_vpc.id

  tags = {
    Name = "${var.sys_name}-${var.env}-servicer-alb-sg"
  }
}

# Ingress Rule（HTTPS from all）
resource "aws_vpc_security_group_ingress_rule" "in_https_from_all" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow HTTPS from anywhere"
}

# Egress Rule（8080）
resource "aws_vpc_security_group_egress_rule" "out_8080_from_elb" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = data.aws_vpc.themis2_vpc.cidr_block
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  description       = "Allow outbound 8080 to VPC"
}

# Egress Rule（8000）
resource "aws_vpc_security_group_egress_rule" "out_8000_from_elb" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = data.aws_vpc.themis2_vpc.cidr_block
  from_port         = 8000
  to_port           = 8000
  ip_protocol       = "tcp"
  description       = "Allow outbound 8000 to VPC"
}

# Egress Rule（3000）
resource "aws_vpc_security_group_egress_rule" "out_3000_from_elb" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = data.aws_vpc.themis2_vpc.cidr_block
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  description       = "Allow outbound 3000 to VPC"
}
