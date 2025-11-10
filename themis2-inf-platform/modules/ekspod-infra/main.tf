# Kubernetes endpoint
data "aws_eks_cluster" "eks_data" {
  name = "${var.sys_name}-${var.env}-eks-cp-${var.cluster_identifier_infra}"
}

data "aws_eks_cluster_auth" "eks_data" {
  name = data.aws_eks_cluster.eks_data.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_data.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_data.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_data.token
}

# EKSのイングレスで利用するセキュリティグループをタグのNameを指定しdataで取得
data "aws_security_group" "eks_ingress_sg" {
  filter {
    name = "tag:Name"
    values = [
      "${var.sys_name}-${var.env}-alb-sg"
    ]
  }
}

# タグ名パターンに基づいてNAT GatewayのIPを取得
data "aws_nat_gateways" "servicer_nat_gateways" {
  filter {
    name   = "tag:Name"
    values = ["${var.sys_name}-${var.env}-servicer-nat-*"]
  }
}

# 個々のNAT Gatewayの詳細を取得
data "aws_nat_gateway" "servicer_nat_gateways" {
  for_each = toset(data.aws_nat_gateways.servicer_nat_gateways.ids)
  id       = each.value
}

# NAT Gateway IPのマップを作成
locals {
  servicer_nat_gateway_cidr_blocks = [
    for nat_gw in data.aws_nat_gateway.servicer_nat_gateways : 
    "${nat_gw.public_ip}/32"
  ]
}

# External application
## eltres-console(iotagent-console)
resource "kubernetes_manifest" "iotagent_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/iotagent-console/iotagent-console-dply.yaml.tpl", {
    env             = var.env,
    sys_name        = var.sys_name,
    ns_option_value = var.ns_option_value,
    aws_account_id  = var.aws_account_id,
    iotagent_endpoint_url = "https://${var.alb_api_domains.iotagent}",
    keycloak_endpoint_url = "https://${var.alb_api_domains.keycloak}"
  }))

  depends_on = [
    kubernetes_manifest.iotagent_svc,
    kubernetes_manifest.iotagent_tgb,
    kubernetes_manifest.iotagent_configmap,
    kubernetes_manifest.iotagent_secret
  ]

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "iotagent_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/iotagent-console/iotagent-console-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name,
  }))
}

resource "kubernetes_manifest" "iotagent_configmap" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/iotagent-console/iotagent-console-configmap.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name,
  }))
}

resource "kubernetes_manifest" "iotagent_secret" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/iotagent-console/iotagent-console-secret.yaml.tpl", {
    env                                     = var.env,
    sys_name                                = var.sys_name,
    iotagent_console_keycloak_client_secret = base64encode(var.iotagent_console_keycloak_client_secret)
  }))
}

resource "kubernetes_manifest" "iotagent_tgb" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/iotagent-console/iotagent-console-tgb.yaml.tpl", {
    iotagent_tg_arn = var.iotagent_tg_arn,
    env             = var.env,
    sys_name        = var.sys_name,
    pub_sg          = data.aws_security_group.eks_ingress_sg.id
  }))

  depends_on = [
    kubernetes_manifest.iotagent_svc
  ]
}

resource "kubernetes_manifest" "iotagent_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/iotagent-console/iotagent-console-network-policy.yaml.tpl", {
    env                               = var.env,
    sys_name                          = var.sys_name,
    iac_subnet_cidr_block             = var.iac_subnet_cidr_block,
    eks_data_plane_subnet_cidr_blocks = var.eks_data_plane_subnet_cidr_blocks
  }))
}

## keycloak
resource "kubernetes_manifest" "keycloak_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/auth-keycloak/auth-keycloak-dply.yaml.tpl", {
    env                   = var.env,
    sys_name              = var.sys_name,
    keycloak_endpoint_url = "https://${var.alb_api_domains.keycloak}",
    aurora_db_endpoint    = var.aurora_db_endpoint
  }))

  depends_on = [
    kubernetes_manifest.keycloak_svc,
    kubernetes_manifest.keycloak_tgb,
    kubernetes_manifest.keycloak_secret
  ]

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "keycloak_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/auth-keycloak/auth-keycloak-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name,
  }))
}

resource "kubernetes_manifest" "keycloak_tgb" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/auth-keycloak/auth-keycloak-tgb.yaml.tpl", {
    keycloak_tg_arn = var.keycloak_tg_arn,
    env             = var.env,
    sys_name        = var.sys_name,
    pub_sg          = data.aws_security_group.eks_ingress_sg.id
  }))

  depends_on = [
    kubernetes_manifest.keycloak_svc
  ]
}

resource "kubernetes_manifest" "keycloak_secret" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/auth-keycloak/auth-keycloak-secret.yaml.tpl", {
    keycloak_tg_arn                 = var.keycloak_tg_arn,
    env                             = var.env,
    sys_name                        = var.sys_name,
    pub_sg                          = data.aws_security_group.eks_ingress_sg.id,
    keycloak_setting_admin_username = base64encode(var.keycloak_setting_admin_username),
    keycloak_setting_admin_password = base64encode(var.keycloak_setting_admin_password)
  }))
}

resource "kubernetes_manifest" "keycloak_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/auth-keycloak/auth-keycloak-network-policy.yaml.tpl", {
    env                               = var.env,
    sys_name                          = var.sys_name,
    iac_subnet_cidr_block             = var.iac_subnet_cidr_block,
    eks_data_plane_subnet_cidr_blocks = var.eks_data_plane_subnet_cidr_blocks
  }))
}

## platform
resource "kubernetes_manifest" "platform_console_secret" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/platform-console/platform-console-secret.yaml.tpl", {
    env                    = var.env,
    sys_name               = var.sys_name,
    keycloak_client_id     = base64encode(var.platform_console_keycloak_client_id),
    keycloak_client_secret = base64encode(var.platform_console_keycloak_client_secret)
  }))
}

resource "kubernetes_manifest" "platform_console_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/platform-console/platform-console-dply.yaml.tpl", {
    env                     = var.env,
    sys_name                = var.sys_name,
    aws_account_id          = var.aws_account_id,
    keycloak_endpoint_url   = "https://${var.alb_api_domains.keycloak}",
    keycloak_realm          = var.sys_name,
    aurora_db_endpoint      = var.aurora_db_endpoint
  }))

  depends_on = [
    kubernetes_manifest.platform_console_secret
  ]

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "platform_console_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/platform-console/platform-console-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name,
  }))
}

resource "kubernetes_manifest" "platform_console_tgb" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/platform-console/platform-console-tgb.yaml.tpl", {
    platform_console_tg_arn = var.platform_console_tg_arn,
    env                     = var.env,
    sys_name                = var.sys_name,
    pub_sg                  = data.aws_security_group.eks_ingress_sg.id
  }))

  depends_on = [
    kubernetes_manifest.platform_console_svc
  ]
}

resource "kubernetes_manifest" "platform_console_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/platform-console/platform-console-network-policy.yaml.tpl", {
    env                               = var.env,
    sys_name                          = var.sys_name,
    iac_subnet_cidr_block             = var.iac_subnet_cidr_block,
    eks_data_plane_subnet_cidr_blocks = var.eks_data_plane_subnet_cidr_blocks
  }))
}

# Internal application
## eltres-agent
data "aws_iot_endpoint" "current" {}

resource "kubernetes_manifest" "eltres_agent_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/eltres-agent/eltres-agent-dply.yaml.tpl", {
    env                 = var.env,
    sys_name            = var.sys_name,
    ns_option_value     = var.ns_option_value,
    aws_account_id      = var.aws_account_id,
    iot_core_endpoint   = data.aws_iot_endpoint.current.endpoint_address,
    aurora_db_endpoint  = var.aurora_db_endpoint,
    elasticache_endpoint = var.elasticache_endpoint,
    eltres_agent_topics = var.eltres_agent_topics
  }))

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "eltres_agent_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/eltres-agent/eltres-agent-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "eltres_agent_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/eltres-agent/eltres-agent-network-policy.yaml.tpl", {
    env                               = var.env,
    sys_name                          = var.sys_name,
    iac_subnet_cidr_block             = var.iac_subnet_cidr_block,
    eks_data_plane_subnet_cidr_blocks = var.eks_data_plane_subnet_cidr_blocks,
    servicer_nat_gateway_cidr_blocks  = local.servicer_nat_gateway_cidr_blocks
  }))
}

## docdb-realtime-notification-api
resource "kubernetes_manifest" "docdb_realtime_notification_api_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/docdb-realtime-notyfi/docdb-realtime-notification-api-dply.yaml.tpl", {
    env                = var.env,
    sys_name           = var.sys_name,
    aurora_db_endpoint = var.aurora_db_endpoint,
    ecr_url            = var.ecr_docdb_realtime_notification_api_url
  }))

  depends_on = [
    kubernetes_manifest.docdb_realtime_notification_api_svc
  ]

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "docdb_realtime_notification_api_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/docdb-realtime-notyfi/docdb-realtime-notification-api-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "docdb_realtime_notification_api_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/docdb-realtime-notyfi/docdb-realtime-notification-api-network-policy.yaml.tpl", {
    env                   = var.env,
    sys_name              = var.sys_name,
    iac_subnet_cidr_block = var.iac_subnet_cidr_block
  }))
}

## docdb-data-controller-api
resource "kubernetes_manifest" "docdb_data_controller_api_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/docdb-data-crtl-api/docdb-data-controller-api-dply.yaml.tpl", {
    env                = var.env,
    sys_name           = var.sys_name,
    cygnus_mongo_uri   = "mongodb://${var.cygnus_docdb_master_username}:${var.cygnus_docdb_master_password}@${var.cygnus_docdb_endpoint}:${var.cygnus_docdb_port}/sth_themis2?replicaSet=rs0&tls=true&retryWrites=false&tlsAllowInvalidCertificates=true&authMechanism=SCRAM-SHA-1",
    aurora_db_endpoint = var.aurora_db_endpoint,
    ecr_url            = var.ecr_docdb_data_controller_api_url
  }))

  depends_on = [
    kubernetes_manifest.docdb_data_controller_api_svc
  ]

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "docdb_data_controller_api_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/docdb-data-crtl-api/docdb-data-controller-api-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "docdb_data_controller_api_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/docdb-data-crtl-api/docdb-data-controller-api-network-policy.yaml.tpl", {
    env                               = var.env,
    sys_name                          = var.sys_name,
    iac_subnet_cidr_block             = var.iac_subnet_cidr_block,
    eks_data_plane_subnet_cidr_blocks = var.eks_data_plane_subnet_cidr_blocks
  }))
}

# Infrastructure

##fiware cygnus
resource "kubernetes_manifest" "fiware_cygnus_dply" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-cygnus/fiware-cygnus-dply.yaml.tpl", {
    env            = var.env,
    sys_name       = var.sys_name,
    aws_account_id = var.aws_account_id,
    ns_infra_value = var.ns_infra_value
  }))

  depends_on = [
    kubernetes_manifest.fiware_cygnus_svc,
    kubernetes_manifest.fiware_cygnus_agent_configmap,
    kubernetes_manifest.cygnus_mongodb_secret
  ]
}

resource "kubernetes_manifest" "fiware_cygnus_svc" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-cygnus/fiware-cygnus-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "fiware_cygnus_configmap" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-cygnus/fiware-cygnus-configmap.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "cygnus_mongodb_secret" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-cygnus/cygnus-mongodb-secret.yaml.tpl", {
    env                           = var.env,
    sys_name                      = var.sys_name,
    cygnus_mongo_admin            = base64encode(var.cygnus_docdb_master_username),
    cygnus_mongo_admin_password   = base64encode(var.cygnus_docdb_master_password)
  }))
}

resource "kubernetes_manifest" "fiware_cygnus_agent_configmap" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-cygnus/fiware-cygnus-agent-configmap.yaml.tpl", {
    env                           = var.env,
    sys_name                      = var.sys_name,
    host                          = "${var.cygnus_docdb_endpoint}:${var.cygnus_docdb_port}",
    username                      = var.cygnus_docdb_master_username,
    password                      = var.cygnus_docdb_master_password,
    mongo_ssl_truststore_password = var.mongo_ssl_truststore_password
  }))
}

resource "kubernetes_manifest" "fiware_cygnus_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-cygnus/fiware-cygnus-network-policy.yaml.tpl", {
    env                               = var.env,
    sys_name                          = var.sys_name,
    iac_subnet_cidr_block             = var.iac_subnet_cidr_block,
    eks_data_plane_subnet_cidr_blocks = var.eks_data_plane_subnet_cidr_blocks
  }))
}

##fiware orion
resource "kubernetes_manifest" "fiware_orion_dply" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-orion/fiware-orion-dply.yaml.tpl", {
    env             = var.env,
    sys_name        = var.sys_name,
    orion_mongo_uri = "mongodb://${var.orion_docdb_master_username}:${var.orion_docdb_master_password}@${var.orion_docdb_endpoint}:${var.orion_docdb_port}/?replicaSet=rs0&tls=true&retryWrites=false&tlsAllowInvalidCertificates=true&authMechanism=SCRAM-SHA-1"
  }))

  depends_on = [
    kubernetes_manifest.fiware_orion_svc,
    kubernetes_manifest.orion_mongodb_secret
  ]
}

resource "kubernetes_manifest" "fiware_orion_svc" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-orion/fiware-orion-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "orion_mongodb_secret" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-orion/orion-mongodb-secret.yaml.tpl", {
    env                           = var.env,
    sys_name                      = var.sys_name,
    orion_mongo_admin             = base64encode(var.orion_docdb_master_username),
    orion_mongo_admin_password    = base64encode(var.orion_docdb_master_password)
  }))
}

resource "kubernetes_manifest" "fiware_orion_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-orion/fiware-orion-network-policy.yaml.tpl", {
    env                               = var.env,
    sys_name                          = var.sys_name,
    iac_subnet_cidr_block             = var.iac_subnet_cidr_block,
    eks_data_plane_subnet_cidr_blocks = var.eks_data_plane_subnet_cidr_blocks,
    servicer_nat_gateway_cidr_blocks  = local.servicer_nat_gateway_cidr_blocks
  }))
}

##konggateway
resource "kubernetes_manifest" "konggateway_dply" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/konggateway/konggateway-dply.yaml.tpl", {
    env                = var.env,
    sys_name           = var.sys_name,
    aws_account_id     = var.aws_account_id,
    ns_infra_value     = var.ns_infra_value
    aurora_db_endpoint = var.aurora_db_endpoint
  }))

  depends_on = [
    kubernetes_manifest.konggateway_configmap,
    kubernetes_manifest.konggateway_admin_svc,
    kubernetes_manifest.konggateway_proxy_svc,
    kubernetes_manifest.konggateway_sa,
    kubernetes_manifest.postgresql_secret
  ]
  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "konggateway_configmap" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/konggateway/konggateway-configmap.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "konggateway_admin_svc" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/konggateway/konggateway-admin-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "konggateway_proxy_svc" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/konggateway/konggateway-proxy-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "konggateway_sa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/konggateway/konggateway-sa.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "konggateway_tgb" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/konggateway/konggateway-tgb.yaml.tpl", {
    external_kong_tg_arn = var.external_kong_tg_arn,
    env                  = var.env,
    sys_name             = var.sys_name,
    pub_sg               = data.aws_security_group.eks_ingress_sg.id
  }))

  depends_on = [
    kubernetes_manifest.konggateway_proxy_svc
  ]
}

resource "kubernetes_manifest" "postgresql_secret" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/konggateway/postgresql-secret.yaml.tpl", {
    env                = var.env,
    sys_name           = var.sys_name,
    postgresql_user    = base64encode(var.aurora_db_master_username),
    postgresql_password = base64encode(var.aurora_db_master_password)
  }))
}

resource "kubernetes_manifest" "konggateway_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/konggateway/konggateway-network-policy.yaml.tpl", {
    env                               = var.env,
    sys_name                          = var.sys_name,
    vpc_cidr_block                    = var.vpc_cidr_block,
    iac_subnet_cidr_block             = var.iac_subnet_cidr_block,
    eks_data_plane_subnet_cidr_blocks = var.eks_data_plane_subnet_cidr_blocks,
    servicer_nat_gateway_cidr_blocks  = local.servicer_nat_gateway_cidr_blocks
  }))
}

##fiware iotagent-json
resource "kubernetes_manifest" "fiware_iotagent_json_dply" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-iotagent/fiware-iotagent-dply.yaml.tpl", {
    env               = var.env,
    sys_name          = var.sys_name,
    docdb_port        = var.orion_docdb_port,
    iot_core_endpoint = data.aws_iot_endpoint.current.endpoint_address
  }))

  depends_on = [
    kubernetes_manifest.fiware_iotagent_json_svc,
    kubernetes_manifest.fiware_iotagent_auth_host_secret,
    kubernetes_secret.fiware_iotagent_json_certs_secret
  ]
}

resource "kubernetes_manifest" "fiware_iotagent_json_svc" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-iotagent/fiware-iotagent-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "fiware_iotagent_auth_host_secret" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-iotagent/fiware-iotagent-auth-host-secret.yaml.tpl", {
    env       = var.env,
    sys_name  = var.sys_name,
    auth_host = base64encode("${var.orion_docdb_master_username}:${var.orion_docdb_master_password}@${var.orion_docdb_endpoint}")
  }))
}

resource "kubernetes_secret" "fiware_iotagent_json_certs_secret" {
  metadata {
    name      = "${var.sys_name}-${var.env}-json-certs"
    namespace = "default"
  }

  type = "Opaque"

  data = {
    "AmazonRootCA.crt"   = file("${path.module}/../iot-core/aws-certs/AmazonRootCA.crt")
    "certificate.pem"    = var.iot_certificate_pem
    "private-client.key" = var.iot_private_key
  }
}

resource "kubernetes_manifest" "fiware_iotagent_json_tgb" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-iotagent/fiware-iotagent-tgb.yaml.tpl", {
    iotagent_json_tg_arn = var.iotagent_json_tg_arn,
    env                  = var.env,
    sys_name             = var.sys_name,
    pub_sg               = data.aws_security_group.eks_ingress_sg.id
  }))

  depends_on = [
    kubernetes_manifest.fiware_iotagent_json_svc
  ]
}

resource "kubernetes_manifest" "fiware_iotagent_json_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/fiware-iotagent/fiware-iotagent-network-policy.yaml.tpl", {
    env                               = var.env,
    sys_name                          = var.sys_name,
    iac_subnet_cidr_block             = var.iac_subnet_cidr_block,
    eks_data_plane_subnet_cidr_blocks = var.eks_data_plane_subnet_cidr_blocks
  }))
}

## cluster auto scaler
resource "kubernetes_manifest" "cluster_autoscaler_sa" {
  manifest = yamldecode(file("${path.module}/infra_yaml_tpl/auto-cluster/cluster-autoscaler-service-account.yaml.tpl"))

}

resource "kubernetes_manifest" "cluster_autoscaler_clrole" {
  manifest = yamldecode(file("${path.module}/infra_yaml_tpl/auto-cluster/cluster-autoscaler-cluster-role.yaml.tpl"))

  depends_on = [
    kubernetes_manifest.cluster_autoscaler_sa
  ]
}

resource "kubernetes_manifest" "cluster_autoscaler_clrole_binding" {
  manifest = yamldecode(file("${path.module}/infra_yaml_tpl/auto-cluster/cluster-autoscaler-cluster-role-binding.yaml.tpl"))

  depends_on = [
    kubernetes_manifest.cluster_autoscaler_clrole
  ]
}

resource "kubernetes_manifest" "cluster_autoscaler_role" {
  manifest = yamldecode(file("${path.module}/infra_yaml_tpl/auto-cluster/cluster-autoscaler-role.yaml.tpl"))

  depends_on = [
    kubernetes_manifest.cluster_autoscaler_sa
  ]
}

resource "kubernetes_manifest" "cluster_autoscaler_role_binding" {
  manifest = yamldecode(file("${path.module}/infra_yaml_tpl/auto-cluster/cluster-autoscaler-role-binding.yaml.tpl"))

  depends_on = [
    kubernetes_manifest.cluster_autoscaler_role
  ]
}

resource "kubernetes_manifest" "cluster_autoscaler_dply" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/auto-cluster/cluster-autoscaler-dply.yaml.tpl", {
    k8s_cluster_name           = data.aws_eks_cluster.eks_data.name,
    cluster_autoscaler_version = var.cluster_autoscaler_version
  }))

  depends_on = [
    kubernetes_manifest.cluster_autoscaler_clrole_binding,
    kubernetes_manifest.cluster_autoscaler_role_binding,    
    kubernetes_secret.fiware_iotagent_json_certs_secret
  ]
}

## Horizontal pod autoscaler
resource "kubernetes_manifest" "eltres_agent_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/eltres-agent/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "iotagent_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/iotagent-console/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "fiware_cygnus_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/fiware-cygnus/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "fiware_orion_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/fiware-orion/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "keycloak_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/keycloak/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "kong_gateway_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/kong-gateway/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "docdb_realtime_notification_api_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/docdb-realtime-notification-api/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "docdb_data_controller_api_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/docdb-data-control-api/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "iotagent_json_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/iotagent-json/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "platform_console_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/platform-console/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "kong_setting" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/konggateway/kong-setting.yaml.tpl", {
    env                  = var.env,
    sys_name             = var.sys_name
    kong_setting_ecr_url = var.kong_setting_ecr_url
  }))
}

resource "kubernetes_manifest" "postgres_setting" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/postgres/postgres-setting.yaml.tpl", {
    env                      = var.env,
    sys_name                 = var.sys_name
    aurora_db_endpoint       = "postgresql://${var.aurora_db_master_username}:${var.aurora_db_master_password}@${var.aurora_db_endpoint}:5432/${var.postgres_setting_db_name}?schema=public"
    postgres_setting_ecr_url = var.postgres_setting_ecr_url
  }))
}

resource "kubernetes_manifest" "keycloak_setting_configmap" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/keycloak/keycloak-setting-configmap.yaml.tpl", {
    env         = var.env,
    sys_name    = var.sys_name
    init_script = indent(4, file("${path.module}/../../externals/keycloak/init.sh"))
  }))
}


resource "kubernetes_manifest" "keycloak_setting_platform_console" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/keycloak/keycloak-setting.yaml.tpl", {
    env             = var.env,
    sys_name        = var.sys_name
    module_name     = "platform-console"
    admin_username  = var.keycloak_setting_admin_username
    admin_password  = var.keycloak_setting_admin_password
    new_realm       = var.keycloak_setting_new_realm
    client_id_value = "platform-console"
    client_root_url = var.keycloak_setting_client_root_url_platform_console
    user_username   = var.keycloak_setting_user_username
    user_password   = var.keycloak_setting_user_password
  }))

  depends_on = [kubernetes_manifest.keycloak_setting_configmap]
}

resource "kubernetes_manifest" "keycloak_setting_eltres_console" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/keycloak/keycloak-setting.yaml.tpl", {
    env             = var.env,
    sys_name        = var.sys_name
    module_name     = "eltres-console"
    admin_username  = var.keycloak_setting_admin_username
    admin_password  = var.keycloak_setting_admin_password
    new_realm       = var.keycloak_setting_new_realm
    client_id_value = "console"
    client_root_url = var.keycloak_setting_client_root_url_eltres_console
    user_username   = var.keycloak_setting_user_username
    user_password   = var.keycloak_setting_user_password
  }))

  depends_on = [kubernetes_manifest.keycloak_setting_configmap]
}

# metrics-server
resource "kubernetes_manifest" "metrics_sa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/metrics-server/metrics-server-sa.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "metrics_clusterrole_aggregated_reader" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/metrics-server/metrics-server-cr-aggregated.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "metrics_clusterrole_main" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/metrics-server/metrics-server-cr.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "metrics_rolebinding" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/metrics-server/metrics-server-rolebinding.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "metrics_clusterrolebinding_auth" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/metrics-server/metrics-server-crb-auth-delegator.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "metrics_clusterrolebinding_main" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/metrics-server/metrics-server-crb.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "metrics_svc" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/metrics-server/metrics-server-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "metrics_dply" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/metrics-server/metrics-server-dply.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "metrics_apisvc" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/metrics-server/metrics-server-apiservice.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}
