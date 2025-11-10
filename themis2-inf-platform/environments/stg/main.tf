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
  vpc_cidr_block     = var.cidr_block
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

  ## アドオンのバージョン
  kube_proxy_version = var.kube_proxy_version
  vpc_cni_version    = var.vpc_cni_version
  coredns_version    = var.coredns_version

  init_script = var.eks_node_init_script
}

# acm
module "acm" {
  source = "../../modules/acm"
  providers = {
    aws.virginia = aws.virginia
  }

  domain_name = local.sub_domain_name
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

# iot core
module "iot_core" {
  source = "../../modules/iot-core"

  sys_name       = var.sys_name
  env            = var.env
  aws_account_id = var.aws_account_id
}

module "alb" {
  source = "../../modules/alb"

  sys_name                         = var.sys_name
  env                              = var.env
  region                           = var.use_region
  vpc_id                           = module.vpc.vpc_id
  iotagent_cf                      = var.iotagent_cf
  keycloak_cf                      = var.keycloak_cf
  platform_console_cf              = var.platform_console_cf
  external_kong_cf                 = var.external_kong_cf
  s3_alb_accesslog_expiration_days = var.s3_alb_accesslog_expiration_days
  https_crt_arn                    = module.acm.alb_crt_arn
  api_domains                      = local.alb_api_domains
  iotagent_json_cf                 = var.iotagent_json_cf
}

# データプラットフォーム クラスター
module "ekspod_infra" {
  source = "../../modules/ekspod-infra"

  cluster_identifier_infra = var.cluster_identifier["infra"] //クラスター 識別用

  sys_name                = var.sys_name
  env                     = var.env
  vpc_cidr_block          = var.cidr_block
  ns_option_value         = var.ns_option_value
  ns_infra_value          = var.ns_infra_value
  iotagent_tg_arn         = module.alb.iotagent_tg_arn
  keycloak_tg_arn         = module.alb.keycloak_tg_arn
  platform_console_tg_arn = module.alb.platform_console_tg_arn
  external_kong_tg_arn    = module.alb.external_kong_tg_arn
  iotagent_json_tg_arn    = module.alb.iotagent_json_tg_arn

  alb_api_domains                         = local.alb_api_domains
  platform_console_keycloak_client_id     = var.platform_console_keycloak_client_id
  platform_console_keycloak_client_secret = var.platform_console_keycloak_client_secret
  iotagent_console_keycloak_client_secret = var.iotagent_console_keycloak_client_secret

  orion_docdb_master_username             = var.orion_docdb_clusters.docdb_master_username
  orion_docdb_master_password             = var.orion_docdb_master_password
  orion_docdb_endpoint                    = module.orion_docdb.docdb_endpoint
  orion_docdb_port                        = module.orion_docdb.docdb_port
  cygnus_docdb_master_username            = var.cygnus_docdb_clusters.docdb_master_username
  cygnus_docdb_master_password            = var.cygnus_docdb_master_password
  cygnus_docdb_endpoint                   = module.cygnus_docdb.docdb_endpoint
  cygnus_docdb_port                       = module.cygnus_docdb.docdb_port
  mongo_ssl_truststore_password           = var.mongo_ssl_truststore_password
  ecr_docdb_data_controller_api_url       = module.ecr.docdb_data_controller_api_url
  ecr_docdb_realtime_notification_api_url = module.ecr.docdb_realtime_notification_api_url
  aurora_db_endpoint                      = module.aurora_db.aurora_endpoint
  elasticache_endpoint                    = module.elasticache.endpoint
  aurora_db_master_username               = var.aurora_master_username
  aurora_db_master_password               = var.aurora_master_password
  eltres_agent_topics                     = var.eltres_agent_topics
  cluster_autoscaler_version              = var.cluster_autoscaler_version
  postgres_setting_db_name                = var.postgres_setting_db_name

  keycloak_setting_admin_username                   = var.keycloak_setting_admin_username
  keycloak_setting_admin_password                   = var.keycloak_setting_admin_password
  keycloak_setting_new_realm                        = var.keycloak_setting_new_realm
  keycloak_setting_client_root_url_platform_console = "https://${local.alb_api_domains.platform}"
  keycloak_setting_client_root_url_eltres_console   = "https://${local.alb_api_domains.iotagent}"
  keycloak_setting_user_username                    = var.keycloak_setting_user_username
  keycloak_setting_user_password                    = var.keycloak_setting_user_password

  kong_setting_ecr_url     = module.ecr.kong_setting_url
  postgres_setting_ecr_url = module.ecr.postgres_setting_url

  eks_data_plane_subnet_cidr_blocks = var.eks_data_plane_subnet_cidr_blocks
  iac_subnet_cidr_block             = var.iac_subnet_cidr_block
  aws_account_id                     = var.aws_account_id

  iot_certificate_pem = module.iot_core.certifycate_pem
  iot_private_key     = module.iot_core.private_key_pem
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
  acm_cloudfront_arn             = module.acm.cloudfront_crt_arn
  web_acl_arn                    = module.waf.web_acl_arn
  aliase_domains                 = values(local.alb_api_domains)
  alb_arn                        = module.alb.alb_arn
}

module "waf" {
  source = "../../modules/waf"
  providers = {
    aws.virginia = aws.virginia
  }

  sys_name                         = var.sys_name
  env                              = var.env
  cloudwatch_metrics_value         = var.cloudwatch_metrics_value
  sampled_requests_value           = var.sampled_requests_value
  waf_log_expiration_days          = var.waf_log_expiration_days
  admin_cidr_blocks                = var.iac_allow_cidr_blocks
  grafana_domain_regex             = "^${var.env}-${var.grafana_domain_regex}$"

  allowed_ips = concat(
    module.vpc.nat_gateway_eip_addresses,
    [module.ec2.ec2_eip_address]
  )
}

module "orion_docdb" {
  source = "../../modules/docdb"

  sys_name                   = var.sys_name
  env                        = var.env
  vpc_cidr_block             = var.cidr_block
  vpc_id                     = module.vpc.vpc_id
  eks_cluster_identifier     = var.eks_cluster_identifier
  eks_dataplane_subnet_ids   = module.vpc.eks_controlplane_subnets
  eks_node_security_group_id = module.eks[var.eks_cluster_identifier].node_security_group_id

  docdb_cluster_identifier      = var.orion_docdb_clusters.docdb_cluster_identifier
  docdb_master_username         = var.orion_docdb_clusters.docdb_master_username
  docdb_master_password         = var.orion_docdb_master_password
  docdb_engine_version          = var.docdb_engine_version
  docdb_preferred_backup_window = var.docdb_preferred_backup_window
  docdb_instance_class          = var.docdb_instance_class
}

module "cygnus_docdb" {
  source = "../../modules/docdb"

  sys_name                   = var.sys_name
  env                        = var.env
  vpc_cidr_block             = var.cidr_block
  vpc_id                     = module.vpc.vpc_id
  eks_cluster_identifier     = var.eks_cluster_identifier
  eks_dataplane_subnet_ids   = module.vpc.eks_controlplane_subnets
  eks_node_security_group_id = module.eks[var.eks_cluster_identifier].node_security_group_id

  docdb_cluster_identifier      = var.cygnus_docdb_clusters.docdb_cluster_identifier
  docdb_master_username         = var.cygnus_docdb_clusters.docdb_master_username
  docdb_master_password         = var.cygnus_docdb_master_password
  docdb_engine_version          = var.docdb_engine_version
  docdb_preferred_backup_window = var.docdb_preferred_backup_window
  docdb_instance_class          = var.docdb_instance_class
}

# Aurora Serverless v2 for PostgreSQL
module "aurora_db" {
  source = "../../modules/aurora"

  sys_name                   = var.sys_name
  env                        = var.env
  vpc_cidr_block             = var.cidr_block
  vpc_id                     = module.vpc.vpc_id
  eks_cluster_identifier     = var.aurora_eks_cluster_identifier
  eks_dataplane_subnet_ids   = module.vpc.eks_controlplane_subnets
  eks_node_security_group_id = module.eks[var.aurora_eks_cluster_identifier].node_security_group_id
  engine_version             = var.aurora_engine_version
  master_username            = var.aurora_master_username
  master_password            = var.aurora_master_password
  max_capacity               = var.aurora_max_capacity
  min_capacity               = var.aurora_min_capacity
}

# ElastiCache
module "elasticache" {
  source = "../../modules/elasticache"

  sys_name                         = var.sys_name
  env                              = var.env
  vpc_cidr_block                   = var.cidr_block
  vpc_id                           = module.vpc.vpc_id
  eks_cluster_identifier           = var.elasticache_eks_cluster_identifier
  eks_dataplane_subnet_ids         = module.vpc.eks_controlplane_subnets
  eks_node_security_group_id       = module.eks[var.elasticache_eks_cluster_identifier].node_security_group_id
  elasticache_major_engine_version = var.elasticache_major_engine_version
}
