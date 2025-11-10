# common value

## system name prefix
sys_name = "themis2"

## project environment(poc/dev/stg/prd)
env = "stg"

## use region
use_region = "ap-northeast-1"

# 新規展開の場合true,既存環境がある場合false
is_fresh_deployment = true

## クラスター識別子
# サービサーごとに追加
cluster_identifier = {
  "infra" = "infra"
}

# vpc module parameter

## cidr block
cidr_block = "10.0.0.0/16"

## EKSデータプレーン用プライベートサブネット
eks_data_plane_subnet_cidr_blocks = {
  "subnet1" = "10.0.0.0/20"
  "subnet2" = "10.0.128.0/20"
}

## EKSコントロールプレーン用プライベートサブネット
eks_control_plane_subnet_cidr_blocks = {
  "subnet1" = "10.0.16.0/24"
  "subnet2" = "10.0.144.0/24"
}

## IaC展開サーバー用パブリックサブネット
iac_subnet_cidr_block = "10.0.65.0/28"

## EKS Ingress及びNAT Gateway用パブリックサブネット
eks_ingress_subnet_cidr_blocks = {
  "subnet1" = "10.0.64.0/24"
  "subnet2" = "10.0.192.0/24"
}

# EC2 (IaC)
iac_ami_id                 = "ami-04bc67ba3896b3841"
iac_instance_type          = "t3a.xlarge"
iac_ssh_port_number        = 22
iac_root_volume_size       = 30
iac_root_volume_type       = "gp3"
iac_root_volume_iops       = 3000
iac_root_volume_throughput = 125

# EKS
eks_cluster_version = "1.32"
eks_desired_size    = 2
eks_disk_size       = 40
eks_instance_type   = "m7i.2xlarge"
eks_max_size        = 10
eks_min_size        = 2

# ACM value
domain_name = "unvs-themis.com."

# ECR value
## name space
ns_sample_value = "sample"
ns_option_value = "option"
ns_infra_value  = "infra"

## image tag mutability
image_tag_mutability = "MUTABLE"

# alb value

## alb accesslog expiration value
s3_alb_accesslog_expiration_days = 90

## API domains
## main.tfにて環境名と結合する処理を実施
route53_domain_name = "unvs-themis.com"
alb_api_sub_domains = {
  "keycloak"      = "auth",
  "iotagent"      = "iotagent",
  "platform"      = "platform",
  "kong"          = "kong",
  "iotagent_json" = "iotagent-json"
}

eks_ami_id = "ami-017e6d057f3a88b5f"

# cloudfront value

## cloudfront log expiration days 
cloudfront_log_expiration_days = 90

## log prefix
cloudfront_log_prefix = "cloudfront/access-log"

## iotaget cf
iotagent_cf = "iotagent"

## keycloak cf
keycloak_cf = "keycloak"

## platform console cf
platform_console_cf = "platform-console"

## external kong cf
external_kong_cf = "external-kong"

## iotagent_json cf
iotagent_json_cf = "iotagent-json"

# waf value

## cloudwatch metric value
cloudwatch_metrics_value = "true"

## sampled requests value
sampled_requests_value = "true"

## waf log expiration days 
waf_log_expiration_days = 90

## DocumentDB
eks_cluster_identifier = "infra"

orion_docdb_clusters = {
  docdb_cluster_identifier = "orion"
  docdb_master_username    = "orion_mongodb_admin"
}

cygnus_docdb_clusters = {
  docdb_cluster_identifier = "cygnus"
  docdb_master_username    = "cygnus_mongodb_admin"
}

docdb_engine_version          = "5.0.0"
docdb_preferred_backup_window = "02:00-04:00"
docdb_instance_class          = "db.t3.medium"
## Aurora Severless V2 for PostgreSQL
aurora_eks_cluster_identifier = "infra"
aurora_max_capacity           = 256
aurora_min_capacity           = 0
aurora_engine_version         = "16.6"
aurora_master_username        = "postgres"
## ElastiCache
elasticache_eks_cluster_identifier = "infra"
elasticache_major_engine_version   = "7"
## Postgres Setting
postgres_setting_db_name = "themis2"

# GitHub設定
github_owner = "Planet-MIMAMORI"
github_repos = "SIoT-Themis"
