# common value

## system name prefix
sys_name = "themis2"

# 新規展開の場合true,既存環境がある場合false
is_fresh_deployment = true

## use availability zones
availability_zones = {
  "subnet1" = "ap-northeast-1a"
  "subnet2" = "ap-northeast-1d"
}

## クラスター識別子
# サービサーごとに追加
cluster_identifier = {
  "sol_prov"  = "sol-prov"
  "sol_prov2" = "sol-prov2"
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
iac_ami_id        = "ami-04bc67ba3896b3841"
iac_instance_type = "t3a.xlarge"
iac_allow_cidr_blocks = [
  "118.238.7.66/32",
  "118.238.7.69/32",
  "211.125.136.0/24",
  "211.125.137.0/24",
  "211.125.138.0/24",
  "114.179.36.144/28",
  "211.125.129.158/32",
  "211.125.130.0/24",
  "211.125.129.237/32",
  "211.125.129.238/32",
  "211.125.129.239/32",
  "211.125.129.240/32",
  "211.125.129.166/32",
  "211.125.140.0/24",
  "211.125.142.0/24",
  "211.125.139.0/24",
  "121.103.157.26/32", #パートナー札幌支社IP
  "18.179.202.73/32",  #お客様IP
  "3.114.96.30/32"     #お客様IP
]
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
domain_name = "unvs-themis.com"

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
  "analyzer"        = "analyzer",        # サービサー①
  "tracker"         = "tracker",         # サービサー①
  "grafana"         = "grafana",         # サービサー①
  "analyzer2"       = "analyzer2",       # サービサー②
  "tracker2"        = "tracker2",        # サービサー②
  "grafana2"        = "grafana2",        # サービサー②
  "transformation"  = "transformation",  # サービサー①
  "transformation2" = "transformation2", # サービサー②
  "keycloak2"       = "auth2",           # サービサー①
  "keycloak3"       = "auth3",           # サービサー②
  "servicer"        = "servicer-console",
  "servicer2"       = "servicer2-console"
}

eks_ami_id = "ami-017e6d057f3a88b5f"

# cloudfront value

## cloudfront log expiration days 
cloudfront_log_expiration_days = 90

## log prefix
cloudfront_log_prefix = "cloudfront/access-log"

## sample analyzer cf
sample_analyzer_cf = "sample-analyzer"

## sample tracker cf
sample_tracker_cf = "sample-tracker"

## grafana cf		
grafana_cf = "grafana"

## transformation cf
transformation_cf = "transformation"

## keycloak2 cf
keycloak2_cf = "keycloak2"

## servicer console cf
servicer_console_cf = "servicer-console"
###

## sample analyzer2 cf
sample_analyzer2_cf = "sample-analyzer2"

## sample tracker2 cf
sample_tracker2_cf = "sample-tracker2"

## grafana2 cf
grafana2_cf = "grafana2"

## transformation2 cf
transformation2_cf = "transformation2"

## keycloak3 cf
keycloak3_cf = "keycloak3"

## servicer2 console cf
servicer2_console_cf = "srvcr2-console"
###

# eks value

## batch analyzer key command
batch_analyzer_key_command = "--type ship --key temperature --interval '*/10 * * * *'"

# canary value

## runtime value
canary_runtime_version = "syn-nodejs-puppeteer-9.1"

## start canary flag(true or false)
start_canary = "true"

## s3 canary expiration days 
s3_canary_log_expiration_days = 90

## canary retension period
canary_failure_retention_period = 31
canary_success_retention_period = 31

## canary schedule(minutes)
rate_minutes = 1

# GitHub設定
github_owner = "Planet-MIMAMORI"
github_repos = "SIoT-Themis"
