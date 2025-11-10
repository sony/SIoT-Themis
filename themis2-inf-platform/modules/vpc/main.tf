locals {
  subnet_ids_map = {
    private_eks_dp_1 = aws_subnet.private_eks_dataplane["subnet1"].id
    private_eks_dp_2 = aws_subnet.private_eks_dataplane["subnet2"].id
    private_eks_cp_1 = aws_subnet.private_eks_controlplane["subnet1"].id
    private_eks_cp_2 = aws_subnet.private_eks_controlplane["subnet2"].id
    public_ingress_1 = aws_subnet.public_eks_ingress["subnet1"].id
    public_ingress_2 = aws_subnet.public_eks_ingress["subnet2"].id
    public_iac       = aws_subnet.public_iac.id
  }
}

# vpc
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  tags = {
    Name = "${var.sys_name}-${var.env}-vpc-${var.region}"
  }
}

# Subnet

#resource "aws_subnet" "private_eks_dataplane" {
#  count = length(var.availability_zones)
#  vpc_id            = aws_vpc.this.id
#  cidr_block        = var.eks_dataplane_subnets[count.index]
#  availability_zone = var.availability_zones[count.index]
#
#  tags = {
#    Name = "${var.sys_name}-${var.env}-subnet-private-${var.region}-${var.availability_zones[count.index]}-dataplane"
#  }
#}

## EKSデータプレーン用プライベートサブネット
resource "aws_subnet" "private_eks_dataplane" {
  for_each          = var.availability_zones
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.eks_data_plane_subnet_cidr_blocks[each.key]
  availability_zone = each.value

  tags = {
    Name = "${var.sys_name}-${var.env}-subnet-private-${var.region}-${var.availability_zones[each.key]}-dataplane"
  }
}

## EKSコントロールプレーン用プライベートサブネット
resource "aws_subnet" "private_eks_controlplane" {
  # count = length(var.availability_zones)
  for_each = var.availability_zones

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.eks_control_plane_subnet_cidr_blocks[each.key]
  availability_zone = each.value

  tags = {
    Name = "${var.sys_name}-${var.env}-subnet-private-${var.region}-${var.availability_zones[each.key]}-controlplane"
  }
}

## IaC展開サーバー用パブリックサブネット
resource "aws_subnet" "public_iac" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.iac_subnet_cidr_block
  availability_zone = var.availability_zones["subnet1"]

  tags = {
    Name = "${var.sys_name}-${var.env}-subnet-private-${var.region}-${var.availability_zones["subnet1"]}-iac"
  }
}

## EKS Ingress及びNAT Gateway用パブリックサブネット
resource "aws_subnet" "public_eks_ingress" {
  # count = length(var.availability_zones)
  for_each = var.availability_zones

  vpc_id            = aws_vpc.this.id
  cidr_block        = var.eks_ingress_subnet_cidr_blocks[each.key]
  availability_zone = each.value

  tags = {
    Name                     = "${var.sys_name}-${var.env}-subnet-public-${var.region}-${var.availability_zones[each.key]}-dataplane"
    "kubernetes.io/role/elb" = "1"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.sys_name}-${var.env}-igw"
  }
}

# Elastic IP
resource "aws_eip" "nat_gateway" {
  # count = length(var.availability_zones)
  for_each = var.availability_zones

  tags = {
    Name = "${var.sys_name}-${var.env}-eip-${var.region}-${var.availability_zones[each.key]}"
  }

  depends_on = [
    aws_internet_gateway.this
  ]
}

# NAT Gateway
resource "aws_nat_gateway" "public" {
  # count = length(var.availability_zones)
  for_each = var.availability_zones

  allocation_id     = aws_eip.nat_gateway[each.key].allocation_id
  subnet_id         = aws_subnet.public_eks_ingress[each.key].id
  connectivity_type = "public"

  tags = {
    Name = "${var.sys_name}-${var.env}-nat-${var.region}-${var.availability_zones[each.key]}"
  }

  depends_on = [aws_internet_gateway.this]
}

# ルートテーブル
## パブリックルートテーブル
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.sys_name}-${var.env}-rtb-public"
  }
}

resource "aws_route_table_association" "public" {
  # count = length(var.availability_zones)
  for_each = var.availability_zones

  subnet_id      = aws_subnet.public_eks_ingress[each.key].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "iac" {
  subnet_id      = aws_subnet.public_iac.id
  route_table_id = aws_route_table.public.id
}

## プライベートルートテーブル
resource "aws_route_table" "private" {
  # count = length(var.availability_zones)
  for_each = var.availability_zones

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.public[each.key].id
  }

  tags = {
    Name = "${var.sys_name}-${var.env}-rtb-private-${var.region}-${var.availability_zones[each.key]}"
  }
}

resource "aws_route_table_association" "eks_controlplane" {
  # count = length(var.availability_zones)
  for_each = var.availability_zones

  subnet_id      = aws_subnet.private_eks_controlplane[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "eks_dataplane" {
  # count = length(var.availability_zones)
  for_each = var.availability_zones

  subnet_id      = aws_subnet.private_eks_dataplane[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# ACL を作成
resource "aws_network_acl" "restricted_vpc_acl" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.sys_name}-${var.env}-restricted-vpc-acl"
  }
}

# サブネットを ACL に関連付け
resource "aws_network_acl_association" "restricted_vpc_acl_association" {
  for_each       = local.subnet_ids_map
  subnet_id      = each.value
  network_acl_id = aws_network_acl.restricted_vpc_acl.id

  depends_on = [
    aws_subnet.private_eks_dataplane,
    aws_subnet.private_eks_controlplane,
    aws_subnet.public_eks_ingress,
    aws_subnet.public_iac
  ]
}

# インバウンドルール（すべてのポート許可: 特定の IP 範囲）
resource "aws_network_acl_rule" "inbound_allow_all_tcp" {
  for_each       = toset(var.allowed_cidr_blocks)
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 100 + index(var.allowed_cidr_blocks, each.value) * 10
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = each.value
  from_port      = 0
  to_port        = 65535
}
resource "aws_network_acl_rule" "inbound_allow_all_udp" {
  for_each       = toset(var.allowed_cidr_blocks)
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 200 + index(var.allowed_cidr_blocks, each.value) * 10
  protocol       = "udp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = each.value
  from_port      = 0
  to_port        = 65535
}

# インバウンドルール（TCP）
resource "aws_network_acl_rule" "inbound_allow_other_tcp" {
  for_each       = var.tcp_ports
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 300 + each.value
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = tonumber(each.key)
  to_port        = tonumber(each.key)
}

# インバウンドルール（UDP）
resource "aws_network_acl_rule" "inbound_allow_other_udp" {
  for_each       = var.udp_ports
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 400 + each.value
  protocol       = "udp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = tonumber(each.key)
  to_port        = tonumber(each.key)
}

# インバウンドルール（エフェメラルポート 1024-65535 の許可）
resource "aws_network_acl_rule" "inbound_allow_ephemeral_tcp" {
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 500
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}
resource "aws_network_acl_rule" "inbound_allow_ephemeral_udp" {
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 600
  protocol       = "udp"
  rule_action    = "allow"
  egress         = false
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# アウトバウンドルール（すべてのポート許可: 特定の IP 範囲）
resource "aws_network_acl_rule" "outbound_allow_all_tcp" {
  for_each       = toset(var.allowed_cidr_blocks)
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 1100 + index(var.allowed_cidr_blocks, each.value) * 10
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = each.value
  from_port      = 0
  to_port        = 65535
}
resource "aws_network_acl_rule" "outbound_allow_all_udp" {
  for_each       = toset(var.allowed_cidr_blocks)
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 1200 + index(var.allowed_cidr_blocks, each.value) * 10
  protocol       = "udp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = each.value
  from_port      = 0
  to_port        = 65535
}

# アウトバウンドルール（TCP）
resource "aws_network_acl_rule" "outbound_allow_other_tcp" {
  for_each       = var.tcp_ports
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 1300 + each.value
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = tonumber(each.key)
  to_port        = tonumber(each.key)
}

# アウトバウンドルール（UDP）
resource "aws_network_acl_rule" "outbound_allow_other_udp" {
  for_each       = var.udp_ports
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 1400 + each.value
  protocol       = "udp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = tonumber(each.key)
  to_port        = tonumber(each.key)
}

# アウトバウンドルール（エフェメラルポート 1024-65535 の許可）
resource "aws_network_acl_rule" "outbound_allow_ephemeral_tcp" {
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 1500
  protocol       = "tcp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}
resource "aws_network_acl_rule" "outbound_allow_ephemeral_udp" {
  network_acl_id = aws_network_acl.restricted_vpc_acl.id
  rule_number    = 1600
  protocol       = "udp"
  rule_action    = "allow"
  egress         = true
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# デフォルトのNACLをTerraform管理下に置き、
# 明示的なルールを定義しないことで、すべてのトラフィックを拒否する状態とする
resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.this.default_network_acl_id

  tags = {
    Name = "${var.sys_name}-${var.env}-default-acl"
  }
}

# デフォルトのセキュリティグループをTerraform管理下に置き、
# すべてのインバウンド／アウトバウンド通信を明示的に拒否する設定にする。
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id

  ingress = []
  egress  = []

  tags = {
    Name = "${var.sys_name}-${var.env}-default-sg"
  }
}
