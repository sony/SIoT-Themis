## Data section
data "aws_security_group" "iac" {
  filter {
    name = "vpc-id"
    values = [
      var.vpc_id
    ]
  }
  filter {
    name = "tag:Name"
    values = [
      "${var.sys_name}-${var.env}-sg-ec2-iac"
    ]
  }
}

data "aws_security_group" "eks" {
  filter {
    name = "vpc-id"
    values = [
      var.vpc_id
    ]
  }

  filter {
    name = "tag:Name"
    values = [
      "${var.sys_name}-${var.env}-sg-data-plane-${var.eks_cluster_identifier}"
    ]
  }
}

data "aws_subnet" "eks_dataplane" {
  for_each = toset(var.eks_dataplane_subnet_ids)
  id       = each.value
}

# ElastiCache section

resource "aws_security_group" "this" {
  name        = "${var.sys_name}-${var.env}-elasticache-sg"
  description = "Security group for ElastiCache access from EKS and EC2"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.sys_name}-${var.env}-elasticache-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_iac_ec2" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = data.aws_security_group.iac.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6380
  description                  = "Allow EC2 (IaC) access to ElastiCache Redis port"
}

resource "aws_vpc_security_group_ingress_rule" "allow_eks" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = data.aws_security_group.eks.id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6380
  description                  = "Allow EKS control plane access to ElastiCache Redis port"
}

resource "aws_vpc_security_group_ingress_rule" "allow_eks_node" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = var.eks_node_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 6379
  to_port                      = 6380
  description                  = "Allow EKS nodes access to ElastiCache Redis port"
}

resource "aws_vpc_security_group_egress_rule" "allow_tcp_dns" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = var.vpc_cidr_block
  ip_protocol       = "tcp"
  from_port         = 53
  to_port           = 53
  description       = "Allow outbound TCP DNS"
}

resource "aws_vpc_security_group_egress_rule" "allow_udp_dns" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = var.vpc_cidr_block
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  description       = "Allow outbound UDP DNS"
}

resource "aws_elasticache_serverless_cache" "this" {
  engine               = "redis"
  name                 = "${var.sys_name}-${var.env}-elasticache"
  major_engine_version = var.elasticache_major_engine_version
  security_group_ids   = [aws_security_group.this.id]
  subnet_ids           = var.eks_dataplane_subnet_ids
}
