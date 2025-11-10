locals {
  alb_api_domains = {
    for key, value in var.alb_api_sub_domains :
    key => "${value}.${var.env}.${var.route53_domain_name}"
  }

  sub_domain_name = "${var.env}.${var.domain_name}"
}

module "vpc" {
  source = "../../modules/vpc"

  sys_name            = var.sys_name
  env                 = var.env
  region              = var.use_region
  availability_zones  = var.availability_zones
  allowed_cidr_blocks = var.allowed_cidr_blocks

  # VPC
  cidr_block = var.cidr_block
  ## EKSデータプレーン用プライベートサブネット
  eks_data_plane_subnet_cidr_blocks = var.eks_data_plane_subnet_cidr_blocks
  ## EKSコントロールプレーン用プライベートサブネット
  eks_control_plane_subnet_cidr_blocks = var.eks_control_plane_subnet_cidr_blocks
  ## IaC展開サーバー用プライベートサブネット
  iac_subnet_cidr_block = var.iac_subnet_cidr_block
  ## EKS Ingress及びNAT Gateway用プライベートサブネット
  eks_ingress_subnet_cidr_blocks = var.eks_ingress_subnet_cidr_blocks
}

module "ec2" {
  source = "../../modules/ec2"

  sys_name           = var.sys_name
  env                = var.env
  region             = var.use_region
  availability_zones = values(var.availability_zones)

  vpc_id             = module.vpc.vpc_id
  ami_id             = var.iac_ami_id
  instance_type      = var.iac_instance_type
  subnet_id          = module.vpc.iac_subnet
  allow_cidr_blocks  = var.iac_allow_cidr_blocks
  ssh_port_number    = var.iac_ssh_port_number
  volume_size        = var.iac_root_volume_size
  volume_type        = var.iac_root_volume_type
  volume_iops        = var.iac_root_volume_iops
  volume_throughput  = var.iac_root_volume_throughput
  public_key_content = var.public_key_content
  github_owner       = var.github_owner
  github_repos       = var.github_repos
  github_pat         = var.github_pat
}

data "aws_ami" "ubuntu_eks" {
  most_recent = true             # 最新のAMIを取得
  owners      = ["099720109477"] # CanonicalのオフィシャルAWSアカウント

  filter {
    name   = "name"
    values = ["ubuntu-eks/k8s_${var.eks_cluster_version}/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-????????"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

module "eks" {
  source = "../../modules/eks"

  is_fresh_deployment = var.is_fresh_deployment

  enable_eksctl_wrapper = var.enable_eksctl_wrapper

  ## コントロールプレーン、データプレーン 共通
  sys_name        = var.sys_name
  env             = var.env
  region          = var.use_region
  cluster_version = var.eks_cluster_version
  vpc_id          = module.vpc.vpc_id

  ## クラスター 識別用
  for_each           = var.cluster_identifier
  cluster_identifier = each.value

  ## コントロールプレーン
  cluster_name            = "${var.sys_name}-${var.env}-eks-cp-${each.value}"
  controlplane_subnet_ids = module.vpc.eks_controlplane_subnets[*]
  admin_user_arns         = var.eks_admin_user_arns

  ## データプレーン
  dataplane_subnet_ids = module.vpc.eks_dataplane_subnets[*]
  ingress_subnet_ids   = module.vpc.eks_ingress_subnets[*]
  ami_id               = var.eks_ami_id
  instance_type        = var.eks_instance_type
  disk_size            = var.eks_disk_size
  node_config = {
    min_size     = var.eks_min_size
    max_size     = var.eks_max_size
    desired_size = var.eks_desired_size
    update_config = {
      max_unavailable = 1
    }
  }

  ## add-ons
  kube_proxy_version = var.kube_proxy_version
  vpc_cni_version    = var.vpc_cni_version
  coredns_version    = var.coredns_version

  init_script = var.eks_node_init_script
}

# ecr
module "ecr" {
  source = "../../modules/ecr"

  is_fresh_deployment  = var.is_fresh_deployment
  sys_name             = var.sys_name
  env                  = var.env
  ns_sample_value      = var.ns_sample_value
  ns_option_value      = var.ns_option_value
  ns_infra_value       = var.ns_infra_value
  image_tag_mutability = var.image_tag_mutability
}

module "alb" {
  source = "../../modules/alb"

  sys_name = var.sys_name
  env      = var.env
  region   = var.use_region
  vpc_id   = module.vpc.vpc_id
  ### サービサー①
  sample_analyzer_cf  = var.sample_analyzer_cf
  sample_tracker_cf   = var.sample_tracker_cf
  grafana_cf          = var.grafana_cf
  transformation_cf   = var.transformation_cf
  keycloak2_cf        = var.keycloak2_cf
  servicer_console_cf = var.servicer_console_cf
  ###
  ### サービサー②
  sample_analyzer2_cf  = var.sample_analyzer2_cf
  sample_tracker2_cf   = var.sample_tracker2_cf
  grafana2_cf          = var.grafana2_cf
  transformation2_cf   = var.transformation2_cf
  keycloak3_cf         = var.keycloak3_cf
  servicer2_console_cf = var.servicer2_console_cf
  ###
  s3_alb_accesslog_expiration_days = var.s3_alb_accesslog_expiration_days
  api_domains                      = local.alb_api_domains
  domain_name                      = local.sub_domain_name
}

# サービサー1 クラスター
module "ekspod_sol_prov" {
  source = "../../modules/ekspod-sol-prov"

  cluster_identifier_sol_prov = var.cluster_identifier["sol_prov"]

  aws_account_id                          = var.aws_account_id
  sys_name                                = var.sys_name
  env                                     = var.env
  ns_sample_value                         = var.ns_sample_value
  ns_option_value                         = var.ns_option_value
  ns_infra_value                          = var.ns_infra_value
  sample_analyzer_tg_arn                  = module.alb.sample_analyzer_tg_arn
  sample_tracker_tg_arn                   = module.alb.sample_tracker_tg_arn
  grafana_tg_arn                          = module.alb.grafana_tg_arn
  transformation_tg_arn                   = module.alb.transformation_tg_arn
  keycloak2_tg_arn                        = module.alb.keycloak2_tg_arn
  servicer_console_tg_arn                 = module.alb.servicer_console_tg_arn
  alb_api_domains                         = local.alb_api_domains
  servicer_console_keycloak_client_id     = var.servicer_console_keycloak_client_id
  servicer_console_keycloak_client_secret = var.servicer_console_keycloak_client_secret
  sample_tracker_backend_api_key          = var.sample_tracker_backend_api_key
  bacth_analyzer_data_controller_api_key  = var.bacth_analyzer_data_controller_api_key
  batch_analyzer_key_command              = var.batch_analyzer_key_command
  ecr_servicer_console_url                = module.ecr.ecr_servicer_console1_url
  ecr_grafana_url                         = module.ecr.grafana_url
  cluster_autoscaler_version              = var.cluster_autoscaler_version
  eks_data_plane_subnet_cidr_blocks       = var.eks_data_plane_subnet_cidr_blocks
  iac_subnet_cidr_block                   = var.iac_subnet_cidr_block
  data_filtering_api_backend_api_key      = var.data_filtering_api_backend_api_key
  ecr_data_filtering_api_url              = module.ecr.ecr_data_filtering_api_url
  keycloak_admin                          = var.keycloak_admin
  keycloak_admin_password                 = var.keycloak_admin_password
  postgresql_admin                        = var.postgresql_admin
  postgresql_admin_password               = var.postgresql_admin_password
  keycloak_setting_admin_username         = var.keycloak_setting_admin_username
  keycloak_setting_admin_password         = var.keycloak_setting_admin_password
  keycloak_setting_new_realm              = var.keycloak_setting_new_realm
  keycloak_setting_client_root_url        = "https://${local.alb_api_domains.servicer}"
  keycloak_setting_user_username          = var.keycloak_setting_user_username
  keycloak_setting_user_password          = var.keycloak_setting_user_password
  postgres_setting_ecr_url                = module.ecr.postgres_setting_url
  realtime_notification_api_key           = var.realtime_notification_api_key
}

# サービサー2 クラスター
module "ekspod_sol_prov2" {
  source = "../../modules/ekspod-sol-prov2"

  cluster_identifier_sol_prov2 = var.cluster_identifier["sol_prov2"]

  aws_account_id                          = var.aws_account_id
  sys_name                                = var.sys_name
  env                                     = var.env
  ns_sample_value                         = var.ns_sample_value
  ns_option_value                         = var.ns_option_value
  ns_infra_value                          = var.ns_infra_value
  sample_analyzer2_tg_arn                 = module.alb.sample_analyzer2_tg_arn
  sample_tracker2_tg_arn                  = module.alb.sample_tracker2_tg_arn
  grafana2_tg_arn                         = module.alb.grafana2_tg_arn
  transformation2_tg_arn                  = module.alb.transformation2_tg_arn
  keycloak3_tg_arn                        = module.alb.keycloak3_tg_arn
  servicer2_console_tg_arn                = module.alb.servicer2_console_tg_arn
  alb_api_domains                         = local.alb_api_domains
  servicer_console_keycloak_client_id     = var.servicer_console_keycloak_client_id
  servicer_console_keycloak_client_secret = var.servicer_console_keycloak_client_secret
  sample_tracker_backend_api_key          = var.sample_tracker_backend_api_key
  bacth_analyzer_data_controller_api_key  = var.bacth_analyzer_data_controller_api_key
  batch_analyzer_key_command              = var.batch_analyzer_key_command
  ecr_servicer_console_url                = module.ecr.ecr_servicer_console2_url
  ecr_grafana_url                         = module.ecr.grafana_url
  cluster_autoscaler_version              = var.cluster_autoscaler_version
  eks_data_plane_subnet_cidr_blocks       = var.eks_data_plane_subnet_cidr_blocks
  iac_subnet_cidr_block                   = var.iac_subnet_cidr_block
  data_filtering_api_backend_api_key      = var.data_filtering_api_backend_api_key
  ecr_data_filtering_api_url              = module.ecr.ecr_data_filtering_api_url
  keycloak_admin                          = var.keycloak_admin
  keycloak_admin_password                 = var.keycloak_admin_password
  postgresql_admin                        = var.postgresql_admin
  postgresql_admin_password               = var.postgresql_admin_password
  keycloak_setting_admin_username         = var.keycloak_setting_admin_username
  keycloak_setting_admin_password         = var.keycloak_setting_admin_password
  keycloak_setting_new_realm              = var.keycloak_setting_new_realm
  keycloak_setting_client_root_url        = "https://${local.alb_api_domains.servicer2}"
  keycloak_setting_user_username          = var.keycloak_setting_user_username
  keycloak_setting_user_password          = var.keycloak_setting_user_password
  postgres_setting_ecr_url                = module.ecr.postgres_setting_url
  realtime_notification_api_key           = var.realtime_notification_api_key
}

module "cloudfront" {
  source = "../../modules/cloudfront"
  providers = {
    aws.virginia = aws.virginia
  }

  sys_name                       = var.sys_name
  env                            = var.env
  domain_name                    = local.sub_domain_name
  cloudfront_log_prefix          = var.cloudfront_log_prefix
  cloudfront_log_expiration_days = var.cloudfront_log_expiration_days
  aliase_domains                 = values(local.alb_api_domains)
  alb_arn                        = module.alb.alb_arn
}

module "canary" {
  source = "../../modules/canary"

  sys_name                        = var.sys_name
  env                             = var.env
  canary_runtime_version          = var.canary_runtime_version
  start_canary                    = var.start_canary
  s3_canary_log_expiration_days   = var.s3_canary_log_expiration_days
  canary_failure_retention_period = var.canary_failure_retention_period
  canary_success_retention_period = var.canary_success_retention_period
  rate_minutes                    = var.rate_minutes
}
