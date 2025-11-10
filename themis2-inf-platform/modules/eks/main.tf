## Acount global settings

resource "aws_ebs_encryption_by_default" "this" {
  count = var.is_fresh_deployment ? 1 : 0

  enabled = true
}

## Controle plane

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

resource "aws_security_group" "this" {
  vpc_id      = var.vpc_id
  name        = "${var.sys_name}-${var.env}-sg-eks-control-plane-api-${var.cluster_identifier}"
  description = "EKS cluster additional security group. Accept connection to control plane."

  tags = {
    Name = "${var.sys_name}-${var.env}-sg-eks-control-plane-api-${var.cluster_identifier}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress_from_iac" {
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = data.aws_security_group.iac.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  description                  = "Allow HTTPS access from IaC EC2"
}

data "aws_subnet" "ingress" {
  for_each = toset(var.ingress_subnet_ids)
  id       = each.value
}

resource "aws_security_group" "data_plane" {
  vpc_id      = var.vpc_id
  name        = "${var.sys_name}-${var.env}-sg-data-plane-${var.cluster_identifier}"
  description = "EKS cluster security group for data plane. Allow specific ingress and egress traffic."

  tags = {
    Name = "${var.sys_name}-${var.env}-sg-data-plane-${var.cluster_identifier}"
  }
}

locals {
  alb_subnet_cidrs = [for subnet in data.aws_subnet.ingress : subnet.cidr_block]
}

resource "aws_vpc_security_group_ingress_rule" "ingress_keycloak" {
  for_each          = toset(local.alb_subnet_cidrs)
  security_group_id = aws_security_group.data_plane.id
  cidr_ipv4         = each.key
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
  description       = "Allow ingress to keycloak from ALB subnets"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_app" {
  for_each          = toset(local.alb_subnet_cidrs)
  security_group_id = aws_security_group.data_plane.id
  cidr_ipv4         = each.key
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  description       = "Allow ingress to applications from ALB subnets"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_kong" {
  for_each          = toset(local.alb_subnet_cidrs)
  security_group_id = aws_security_group.data_plane.id
  cidr_ipv4         = each.key
  from_port         = 8000
  to_port           = 8000
  ip_protocol       = "tcp"
  description       = "Allow ingress to konggateway from ALB subnets"
}

resource "aws_vpc_security_group_ingress_rule" "ingress_iotagent_json" {
  for_each               = toset(local.alb_subnet_cidrs)
  security_group_id      = aws_security_group.data_plane.id
  cidr_ipv4              = each.key
  from_port              = 4041
  to_port                = 4041
  ip_protocol            = "tcp"
  description            = "Allow ingress to iotagent_json from ALB subnets"
}

resource "aws_vpc_security_group_egress_rule" "egress_http" {
  security_group_id = aws_security_group.data_plane.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow outbound HTTP to Internet"
}

resource "aws_vpc_security_group_egress_rule" "egress_https" {
  security_group_id = aws_security_group.data_plane.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "Allow outbound HTTPS to Internet"
}

resource "aws_vpc_security_group_egress_rule" "egress_ssh" {
  security_group_id = aws_security_group.data_plane.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow outbound SSH to Internet"
}

resource "aws_vpc_security_group_egress_rule" "egress_dns_tcp" {
  security_group_id = aws_security_group.data_plane.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
  description       = "Allow outbound DNS (TCP) to Internet"
}

resource "aws_vpc_security_group_egress_rule" "egress_dns_udp" {
  security_group_id = aws_security_group.data_plane.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
  description       = "Allow outbound DNS (UDP) to Internet"
}

module "controle_plane" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                    = var.cluster_name
  cluster_version                 = var.cluster_version
  create_iam_role                 = true
  cluster_encryption_config       = {}
  vpc_id                          = var.vpc_id
  control_plane_subnet_ids        = var.controlplane_subnet_ids
  create_cluster_security_group   = true
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
  cluster_additional_security_group_ids = [
    aws_security_group.this.id
  ]
  enable_cluster_creator_admin_permissions = false
  bootstrap_self_managed_addons            = false

  cluster_addons = {
    kube-proxy = {
      addon_version = var.kube_proxy_version
    }
    vpc-cni = {
      addon_version            = var.vpc_cni_version
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }

  tags = {
    Name = "${var.sys_name}-${var.env}-eks-cp-${var.cluster_identifier}"
  }
}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.12"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_ebs_csi_policy = true
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.controle_plane.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = {
    Name = "${var.sys_name}-${var.env}-iam-role-vpc-cni-irsa-${var.cluster_identifier}"
  }
}

## Data plane

### EC2 auto scalling IAM role

resource "aws_iam_instance_profile" "this" {
  name = "${var.sys_name}-${var.env}-eks-iam-instance-profile-${var.cluster_identifier}"
  role = aws_iam_role.this.name

  tags = {
    Name = "${var.sys_name}-${var.env}-eks-iam-instance-profile-${var.cluster_identifier}"
  }
}

data "aws_iam_policy_document" "assume_ec2_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.sys_name}-${var.env}-eks-iam-role-${var.cluster_identifier}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2_role.json

  tags = {
    Name = "${var.sys_name}-${var.env}-eks-iam-role-${var.cluster_identifier}"
  }
}

data "aws_iam_policy" "amazon_eks_worker_node_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

data "aws_iam_policy" "amazon_ec2_container_registry_read_only" {
  arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

data "aws_iam_policy" "amazon_eks_cni_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

data "aws_iam_policy" "amazon_ebs_csi_driver_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "aws_iam_policy" "amazon_cloudWatch_observability_policy" {
  arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

data "aws_iam_policy" "amazon_cloudWatch_observability_xray_policy" {
  arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.amazon_eks_worker_node_policy.arn
}

resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.amazon_ec2_container_registry_read_only.arn
}

resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.amazon_eks_cni_policy.arn
}

resource "aws_iam_role_policy_attachment" "amazon_ebs_csi_driver_policy" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.amazon_ebs_csi_driver_policy.arn
}

resource "aws_iam_role_policy_attachment" "amazon_cloudWatch_observability_policy" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.amazon_cloudWatch_observability_policy.arn
}

resource "aws_iam_role_policy_attachment" "amazon_cloudWatch_observability_xray_policy" {
  role       = aws_iam_role.this.name
  policy_arn = data.aws_iam_policy.amazon_cloudWatch_observability_xray_policy.arn
}

## Create / Delete node pool on eksctl

### ノードプールのボリュームの暗号化に必要な KMS キー
data "aws_ebs_default_kms_key" "this" {}
data "aws_kms_key" "ebs_default" {
  key_id = data.aws_ebs_default_kms_key.this.key_arn
}

# EKS ノードプール削除向けスクリプト
resource "terraform_data" "node_pool_destory_trigger" {
  input = {
    cluster_name    = module.controle_plane.cluster_name
    cluster_region  = var.region
    node_group_name = "${var.sys_name}-${var.env}-eks-dataplane-${var.cluster_identifier}"
  }

  provisioner "local-exec" {
    command = "${path.module}/bin/eksctl-delete-nodepool.sh"
    environment = {
      cluster_name    = self.output.cluster_name
      cluster_region  = self.output.cluster_region
      node_group_name = self.output.node_group_name
    }
    interpreter = [
      "/bin/bash",
      "-c"
    ]
    when = destroy
  }

  depends_on = [
    aws_iam_instance_profile.this,
    module.controle_plane,
    module.vpc_cni_irsa
  ]
}

resource "local_file" "eksctl_config" {
  content = templatefile("${path.module}/eksctl-files/nodegroup.tftpl",
    {
      cluster_name                             = module.controle_plane.cluster_name
      cluster_region                           = var.region
      cluster_security_group_id                = module.controle_plane.cluster_security_group_id
      vpc_id                                   = var.vpc_id
      private_subnet_ids                       = var.dataplane_subnet_ids
      node_group_name                          = "${var.sys_name}-${var.env}-eks-dataplane-${var.cluster_identifier}"
      node_group_desired_size                  = var.node_config.desired_size
      node_group_min_size                      = var.node_config.min_size
      node_group_max_size                      = var.node_config.max_size
      node_group_instance_role_arn             = aws_iam_role.this.arn
      node_group_update_config_max_unavailable = var.node_config.update_config.max_unavailable
      cluster_service_cidr                     = module.controle_plane.cluster_service_cidr
      launch_template_id                       = aws_launch_template.eks_node.id
      launch_template_version                  = aws_launch_template.eks_node.latest_version
    }
  )
  directory_permission = "0755"
  file_permission      = "0644"
  filename             = "${path.module}/eksctl-files/${var.cluster_identifier}-nodegroup.yaml"

  depends_on = [
    aws_iam_instance_profile.this,
    module.controle_plane,
    module.vpc_cni_irsa,
    terraform_data.node_pool_destory_trigger
  ]
}

data "external" "eksctl_get_nodepool" {
  program = [
    "/bin/bash",
    "${path.module}/bin/eks-get-nodepool.sh"
  ]

  query = {
    cluster_name = module.controle_plane.cluster_name
    region       = var.region
  }

  depends_on = [
    local_file.eksctl_config,
    aws_eks_access_policy_association.this
  ]
}

variable "enable_eksctl_wrapper" {
  # 削除時は下記のコマンドを使用する
  # terraform apply -target=module.eks -destroy -var='enable_eksctl_wrapper=false'
  type    = bool
  default = true
}

resource "terraform_data" "eksctl" {
  count   = var.enable_eksctl_wrapper ? 1 : 0

  input = local_file.eksctl_config.filename

  lifecycle {
    replace_triggered_by = [
      local_file.eksctl_config
    ]
  }

  provisioner "local-exec" {
    command = "${path.module}/bin/eksctl-wrapper.sh"
    environment = {
      config_file_path           = self.output
      cluster_name               = module.controle_plane.cluster_name
      cluster_region             = var.region
      remote_cluster_config_data = data.external.eksctl_get_nodepool.result.messages
    }
    interpreter = [
      "/bin/bash",
      "-c"
    ]
    working_dir = path.root
  }

  depends_on = [
    data.external.eksctl_get_nodepool
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = module.controle_plane.cluster_name
  addon_name                  = "coredns"
  addon_version               = var.coredns_version
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name = "${var.sys_name}-${var.env}-eks-dataplane-coredns-${var.cluster_identifier}"
  }

  depends_on = [
    terraform_data.eksctl
  ]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = module.controle_plane.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Name = "${var.sys_name}-${var.env}-eks-dataplane-ebs-csi-driver-${var.cluster_identifier}"
  }

  depends_on = [
    terraform_data.eksctl
  ]
}

# Account Idの呼び出し
data "aws_caller_identity" "current" {}

# terraformによるAWS lb Controllerのインストール
resource "terraform_data" "eks_lb_controller_install" {

  provisioner "local-exec" {
    command = "${path.module}/bin/lbcontroller.sh"
    environment = {
      cluster_name   = module.controle_plane.cluster_name
      cluster_region = var.region
      account_id     = data.aws_caller_identity.current.account_id
      env            = var.env
    }
    interpreter = [
      "/bin/bash",
      "-c"
    ]
    when = create
  }

  depends_on = [
    terraform_data.eksctl,
    aws_eks_access_policy_association.this
  ]
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name                = module.controle_plane.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  configuration_values = jsonencode({
    agent = {
      config = {
        logs = {
          metrics_collected = {
            application_signals = {},
            kubernetes = {
              enhanced_container_insights = true,
              accelerated_compute_metrics = false
            }
          }
        }
        traces = {
          traces_collected = {
            application_signals = {}
          }
        }
      }
    }
  })

  lifecycle {
    ignore_changes = [ configuration_values ]
  }

  tags = {
    Name = "${var.sys_name}-${var.env}-eks-dataplane-cw-observability-${var.cluster_identifier}"
  }

  depends_on = [
    terraform_data.eksctl,
    terraform_data.eks_lb_controller_install
  ]
}

resource "aws_eks_access_entry" "this" {
  for_each      = toset(var.admin_user_arns)
  cluster_name  = module.controle_plane.cluster_name
  principal_arn = each.key
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
  for_each      = toset(var.admin_user_arns)
  cluster_name  = module.controle_plane.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.key

  access_scope {
    namespaces = []
    type       = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.this
  ]
}

## Cluster auto scaler IAM policy
# https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws#full-cluster-autoscaler-features-policy-recommended
data "aws_iam_policy_document" "node_auto_scale" {
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "node_auto_scale" {
  name   = "${var.sys_name}-${var.env}-eks-node-plane-node-auto-scale-policy-${var.cluster_identifier}"
  path   = "/"
  policy = data.aws_iam_policy_document.node_auto_scale.json
}

resource "aws_iam_role_policy_attachment" "node_auto_scale_policy" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.node_auto_scale.arn
}

## Target Group Binding IAM Policies
data "aws_iam_policy_document" "tgb_elb_access" {
  statement {
    actions = [
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:SetRulePriorities"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "tgb_elb_access" {
  name   = "${var.sys_name}-${var.env}-eks-tgb-policy-${var.cluster_identifier}"
  path   = "/"
  policy = data.aws_iam_policy_document.tgb_elb_access.json
}

resource "aws_iam_role_policy_attachment" "tgb_elb_access_policy" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.tgb_elb_access.arn
}

resource "aws_launch_template" "eks_node" {
  name_prefix            = "${var.sys_name}-${var.env}-eks-launch-template-${var.cluster_identifier}"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  ebs_optimized          = true
  update_default_version = true
  
  metadata_options {
    http_tokens = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.disk_size
      volume_type = "gp3"
      encrypted   = true
      kms_key_id  = data.aws_kms_key.ebs_default.arn
    }
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 30
    }
  }

  user_data = base64encode(<<EOF
#!/bin/bash
/etc/eks/bootstrap.sh '${var.cluster_name}'
${replace(var.init_script, "\r", "")}
EOF
  )
  network_interfaces {
    security_groups = [
      module.controle_plane.node_security_group_id,
      aws_security_group.data_plane.id
    ]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.sys_name}-${var.env}-eks-node-${var.cluster_identifier}"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${var.sys_name}-${var.env}-eks-node-volume-${var.cluster_identifier}"
    }
  }
}
