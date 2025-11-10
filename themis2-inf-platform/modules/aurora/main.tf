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

### Aurora Serverless v2 section
resource "aws_db_subnet_group" "this" {
  name       = "${var.sys_name}-${var.env}-aurora-db-subnet-group"
  subnet_ids = var.eks_dataplane_subnet_ids

  tags = {
    Name = "${var.sys_name}-${var.env}-aurora-db-subnet-group"
  }
}

resource "aws_security_group" "this" {
  name        = "${var.sys_name}-${var.env}-aurora-db-sg"
  description = "${var.sys_name}-${var.env}-aurora-db-sg"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_iac_ec2" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = data.aws_security_group.iac.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_vpc_security_group_ingress_rule" "allow_eks" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = data.aws_security_group.eks.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

resource "aws_vpc_security_group_ingress_rule" "allow_eks_node" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = var.eks_node_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

locals {
  skip_final_snapshot = contains(["prd", "stg"], var.env) ? false : true
}

resource "aws_rds_cluster" "this" {
  cluster_identifier        = "${var.sys_name}-${var.env}-aurora-db"
  engine                    = "aurora-postgresql"
  engine_mode               = "provisioned"
  engine_version            = var.engine_version
  master_username           = var.master_username
  master_password           = var.master_password
  storage_encrypted         = true
  vpc_security_group_ids    = [aws_security_group.this.id]
  db_subnet_group_name      = aws_db_subnet_group.this.name
  skip_final_snapshot       = local.skip_final_snapshot
  final_snapshot_identifier = local.skip_final_snapshot ? null : "${var.sys_name}-${var.env}-final-snapshot"
  backup_retention_period   = 8

  serverlessv2_scaling_configuration {
    max_capacity = var.max_capacity
    min_capacity = var.min_capacity
  }
}

resource "aws_rds_cluster_instance" "aurora_writer" {
  promotion_tier             = 0
  identifier                 = "${aws_rds_cluster.this.id}-writer"
  cluster_identifier         = aws_rds_cluster.this.id
  instance_class             = "db.serverless"
  engine                     = aws_rds_cluster.this.engine
  engine_version             = aws_rds_cluster.this.engine_version
  publicly_accessible        = false
  auto_minor_version_upgrade = false
}

resource "aws_rds_cluster_instance" "aurora_reader" {
  promotion_tier             = 2
  identifier                 = "${aws_rds_cluster.this.id}-reader"
  cluster_identifier         = aws_rds_cluster.this.id
  instance_class             = "db.serverless"
  engine                     = aws_rds_cluster.this.engine
  engine_version             = aws_rds_cluster.this.engine_version
  publicly_accessible        = false
  auto_minor_version_upgrade = false
}
