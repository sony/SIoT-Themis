## Data section
### [TODO] モジュール EC2 から当該セキュリティグループの ID を受け取りたい
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

### DocumentDB section
resource "aws_docdb_subnet_group" "this" {
  name       = "${var.sys_name}-${var.env}-${var.docdb_cluster_identifier}_docdb-subnet-group"
  subnet_ids = var.eks_dataplane_subnet_ids

  tags = {
    Name = "${var.sys_name}-${var.env}-${var.docdb_cluster_identifier}_docdb-subnet-group"
  }
}

resource "aws_security_group" "this" {
  name        = "${var.sys_name}-${var.env}-${var.docdb_cluster_identifier}_docdb-sg"
  description = "${var.sys_name}-${var.env}-${var.docdb_cluster_identifier}_docdb-sg"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "docdb_allow_iac_ec2" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = data.aws_security_group.iac.id
  ip_protocol                  = "tcp"
  from_port                    = 27017
  to_port                      = 27017
}

resource "aws_vpc_security_group_ingress_rule" "docdb_allow_eks" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = data.aws_security_group.eks.id
  ip_protocol                  = "tcp"
  from_port                    = 27017
  to_port                      = 27017
}

resource "aws_vpc_security_group_ingress_rule" "docdb_allow_eks_node" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = var.eks_node_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 27017
  to_port                      = 27017
}

locals {
  skip_final_snapshot = contains(["prd", "stg"], var.env) ? false : true
}

resource "aws_docdb_cluster" "this" {
  cluster_identifier        = "${var.sys_name}-${var.env}-${var.docdb_cluster_identifier}-docdb-cluster"
  engine                    = "docdb"
  engine_version            = var.docdb_engine_version
  availability_zones        = sort([for subnet in data.aws_subnet.eks_dataplane : subnet.availability_zone])
  master_username           = var.docdb_master_username
  master_password           = var.docdb_master_password
  backup_retention_period   = 7
  preferred_backup_window   = var.docdb_preferred_backup_window
  skip_final_snapshot       = local.skip_final_snapshot
  final_snapshot_identifier = local.skip_final_snapshot ? null : "${var.sys_name}-${var.env}-${var.docdb_cluster_identifier}-final-snapshot"
  storage_encrypted         = true
  db_subnet_group_name      = aws_docdb_subnet_group.this.name
  deletion_protection       = true
  vpc_security_group_ids    = [aws_security_group.this.id]

  lifecycle {
    ignore_changes = [
      master_password,
      availability_zones
    ]
  }
}

resource "aws_docdb_cluster_instance" "this" {
  count              = 2
  identifier         = "${var.sys_name}-${var.env}-${var.docdb_cluster_identifier}-docdb-instance-${count.index + 1}"
  cluster_identifier = aws_docdb_cluster.this.id
  instance_class     = var.docdb_instance_class
}
