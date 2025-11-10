data "aws_ebs_default_kms_key" "this" {}

data "aws_kms_key" "this" {
  key_id = data.aws_ebs_default_kms_key.this.key_arn
}

# IAM Role for EC2 instance
resource "aws_iam_role" "ec2_role" {
  name = "${var.sys_name}-${var.env}-ec2-admin-role-iac"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.sys_name}-${var.env}-ec2-role-iac"
  }
}

# Attach AdministratorAccess policy to the role
resource "aws_iam_role_policy_attachment" "administrator_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Create instance profile
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.sys_name}-${var.env}-ec2-profile-iac"
  role = aws_iam_role.ec2_role.name
}

resource "aws_key_pair" "this" {
  key_name   = "${var.sys_name}-${var.env}-keypair-ec2-iac"
  public_key = var.public_key_content
}

resource "aws_eip" "this" {
  instance = aws_instance.this.id
  domain   = "vpc"

  tags = {
    Name = "${var.sys_name}-${var.env}-eip-iac"
  }
}

resource "aws_security_group" "this" {
  vpc_id      = var.vpc_id
  name        = "${var.sys_name}-${var.env}-sg-ec2-iac"
  description = "Security group for workers to SSH to the IaC deployment server"

  tags = {
    Name = "${var.sys_name}-${var.env}-sg-ec2-iac"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh_from_workers" {
  for_each          = toset(var.allow_cidr_blocks)
  security_group_id = aws_security_group.this.id
  description       = "From the workers terminal"
  from_port         = var.ssh_port_number
  to_port           = var.ssh_port_number
  ip_protocol       = "tcp"
  cidr_ipv4         = each.key
}

resource "aws_vpc_security_group_egress_rule" "http" {
  security_group_id = aws_security_group.this.id
  description       = "Allow outbound TCP to VPC for HTTP"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.this.id
  description       = "Allow outbound TCP to VPC for HTTPS"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ssh" {
  security_group_id = aws_security_group.this.id
  description       = "Allow outbound TCP to VPC for SSH"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "dns_tcp" {
  security_group_id = aws_security_group.this.id
  description       = "Allow outbound TCP to VPC for DNS"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "dns_udp" {
  security_group_id = aws_security_group.this.id
  description       = "Allow outbound UDP to VPC for DNS"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "mongodb" {
  security_group_id = aws_security_group.this.id
  description       = "Allow outbound TCP to VPC for mongodb"
  from_port         = 27017
  to_port           = 27017
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr_block
}

resource "aws_vpc_security_group_egress_rule" "postgresql" {
  security_group_id = aws_security_group.this.id
  description       = "Allow outbound TCP to VPC for postgresql"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr_block
}

resource "aws_instance" "this" {
  ami                                  = var.ami_id
  instance_type                        = var.instance_type
  subnet_id                            = var.subnet_id
  instance_initiated_shutdown_behavior = "stop"
  hibernation                          = "false"
  disable_api_termination              = "true"
  vpc_security_group_ids               = [aws_security_group.this.id]
  key_name                             = aws_key_pair.this.key_name
  iam_instance_profile                 = aws_iam_instance_profile.ec2_profile.name
  
  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size           = var.volume_size
    volume_type           = var.volume_type
    iops                  = var.volume_iops
    throughput            = var.volume_throughput
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = data.aws_kms_key.this.arn
  }

  # User data to install multiple GitHub self-hosted runners
  user_data = <<-EOF
              #!/bin/bash
              set -e
              
              # Set variables from Terraform
              export OWNER="${var.github_owner}"
              export GH_REPOS="${var.github_repos}"
              export GH_PAT="${var.github_pat}"
              export ENV="${var.env}"
              export RUNNER_TAG_NAME="${var.runner_tag_name}-${var.env}"
              
              # Execute the setup script
              /bin/bash /opt/setup_github_runner.sh
              
              echo "Setup script execution completed"
              EOF

  lifecycle {
    ignore_changes = [ user_data ]
  }

  tags = {
    Name = "${var.sys_name}-${var.env}-ec2-iac"
  }
}
