# EKSのパブリックサブネットをタグのNameを指定しdataで取得
data "aws_subnets" "eks_public_subnets" {
  filter {
    name = "tag:Name"
    values = [
      "${var.sys_name}-${var.env}-subnet-public-ap-northeast-1-ap-northeast-1a-dataplane",
      "${var.sys_name}-${var.env}-subnet-public-ap-northeast-1-ap-northeast-1d-dataplane"
    ]
  }
}

# alb
resource "aws_lb" "themis2_alb" {
  name               = "${var.sys_name}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.eks_public_subnets.ids
  
  drop_invalid_header_fields = true

  access_logs {
    bucket  = "${var.sys_name}-${var.env}-s3-alb-accesslog"
    prefix  = "access-log"
    enabled = true
  }

  enable_deletion_protection = false
}
