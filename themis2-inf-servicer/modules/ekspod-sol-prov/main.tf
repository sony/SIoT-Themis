# Kubernetes endpoint
data "aws_eks_cluster" "eks_data" {
  name = "${var.sys_name}-${var.env}-eks-cp-${var.cluster_identifier_sol_prov}"
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
      "${var.sys_name}-${var.env}-servicer-alb-sg"
    ]
  }
}

# Get NAT Gateway information by tag name
data "aws_nat_gateways" "platform_nat_gateways" {
  filter {
    name   = "tag:Name"
    values = ["${var.sys_name}-${var.env}-nat-*"]
  }
}

# Get individual NAT Gateway details
data "aws_nat_gateway" "platform_nat_gateways" {
  for_each = toset(data.aws_nat_gateways.platform_nat_gateways.ids)
  id       = each.value
}

locals {
  platform_nat_gateway_cidr_blocks = [
    for nat_gw in data.aws_nat_gateway.platform_nat_gateways :
    "${nat_gw.public_ip}/32"
  ]
}

## sample realtime analyzer
resource "kubernetes_manifest" "sample_analyzer_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/realtime-analyzer/realtime-analyzer-dply.yaml.tpl", {
    env             = var.env,
    sys_name        = var.sys_name,
    ns_sample_value = var.ns_sample_value,
    aws_account_id  = var.aws_account_id
  }))

  depends_on = [
    kubernetes_manifest.sample_analyzer_svc,
    kubernetes_manifest.sample_analyzer_tgb
  ]

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "sample_analyzer_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/realtime-analyzer/realtime-analyzer-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name,
  }))
}

resource "kubernetes_manifest" "sample_analyzer_tgb" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/realtime-analyzer/realtime-analyzer-tgb.yaml.tpl", {
    sample_analyzer_tg_arn = var.sample_analyzer_tg_arn,
    env                    = var.env,
    sys_name               = var.sys_name,
    pub_sg                 = data.aws_security_group.eks_ingress_sg.id
  }))

  depends_on = [
    kubernetes_manifest.sample_analyzer_svc
  ]
}

resource "kubernetes_manifest" "sample_analyzer_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/realtime-analyzer/realtime-analyzer-network-policy.yaml.tpl", {
    env                              = var.env,
    sys_name                         = var.sys_name,
    iac_subnet_cidr_block            = var.iac_subnet_cidr_block,
    platform_nat_gateway_cidr_blocks = local.platform_nat_gateway_cidr_blocks
  }))
}

## sample tracker
resource "kubernetes_manifest" "sample_tracker_secret" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/visualize-tracker/visualize-tracker-secret.yaml.tpl", {
    env                    = var.env,
    sys_name               = var.sys_name,
    base64_backend_api_key = base64encode(var.sample_tracker_backend_api_key)
  }))
}

resource "kubernetes_manifest" "sample_tracker_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/visualize-tracker/visualize-tracker-dply.yaml.tpl", {
    env             = var.env,
    sys_name        = var.sys_name,
    ns_sample_value = var.ns_sample_value,
    aws_account_id  = var.aws_account_id,
    domain          = var.domain
  }))

  depends_on = [
    kubernetes_manifest.sample_tracker_secret
  ]
}

resource "kubernetes_manifest" "sample_tracker_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/visualize-tracker/visualize-tracker-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name,
  }))
}

resource "kubernetes_manifest" "sample_tracker_tgb" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/visualize-tracker/visualize-tracker-tgb.yaml.tpl", {
    sample_tracker_tg_arn = var.sample_tracker_tg_arn,
    env                   = var.env,
    sys_name              = var.sys_name,
    pub_sg                = data.aws_security_group.eks_ingress_sg.id
  }))

  depends_on = [
    kubernetes_manifest.sample_tracker_svc
  ]
}

resource "kubernetes_manifest" "sample_tracker_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/visualize-tracker/visualize-tracker-network-policy.yaml.tpl", {
    env                              = var.env,
    sys_name                         = var.sys_name,
    iac_subnet_cidr_block            = var.iac_subnet_cidr_block,
    platform_nat_gateway_cidr_blocks = local.platform_nat_gateway_cidr_blocks
  }))
}

## realtime transformation
resource "kubernetes_manifest" "realtime_transformation_api_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/realtime-transform/realtime-transformation-api-dply.yaml.tpl", {
    env             = var.env,
    sys_name        = var.sys_name,
    ns_sample_value = var.ns_sample_value,
    aws_account_id  = var.aws_account_id
  }))

  depends_on = [
    kubernetes_manifest.realtime_transformation_api_svc
  ]

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "realtime_transformation_api_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/realtime-transform/realtime-transformation-api-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name,
  }))
}

resource "kubernetes_manifest" "realtime_transformation_api_tgb" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/realtime-transform/realtime-transformation-api-tgb.yaml.tpl", {
    transformation_tg_arn = var.transformation_tg_arn,
    env                   = var.env,
    sys_name              = var.sys_name,
    pub_sg                = data.aws_security_group.eks_ingress_sg.id
  }))

  depends_on = [
    kubernetes_manifest.realtime_transformation_api_svc
  ]
}

resource "kubernetes_manifest" "realtime_transformation_api_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/realtime-transform/realtime-transformation-api-network-policy.yaml.tpl", {
    env                              = var.env,
    sys_name                         = var.sys_name,
    iac_subnet_cidr_block            = var.iac_subnet_cidr_block,
    platform_nat_gateway_cidr_blocks = local.platform_nat_gateway_cidr_blocks
  }))
}

## keycloak
resource "kubernetes_manifest" "keycloak_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/auth-keycloak/auth-keycloak-dply.yaml.tpl", {
    env                   = var.env,
    sys_name              = var.sys_name,
    keycloak_endpoint_url = "https://${var.alb_api_domains.keycloak2}",
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
    keycloak2_tg_arn = var.keycloak2_tg_arn,
    env              = var.env,
    sys_name         = var.sys_name,
    pub_sg           = data.aws_security_group.eks_ingress_sg.id
  }))

  depends_on = [
    kubernetes_manifest.keycloak_svc
  ]
}

resource "kubernetes_manifest" "keycloak_secret" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/auth-keycloak/auth-keycloak-secret.yaml.tpl", {
    keycloak2_tg_arn               = var.keycloak2_tg_arn,
    env                            = var.env,
    sys_name                       = var.sys_name,
    pub_sg                         = data.aws_security_group.eks_ingress_sg.id,
    base64_keycloak_admin          = base64encode(var.keycloak_admin),
    base64_keycloak_admin_password = base64encode(var.keycloak_admin_password)
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

##postgresql
resource "kubernetes_manifest" "postgresql_stfs" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/postgresql/postgresql-stfs.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
    pg_data  = "/data/pgdata"
  }))

  depends_on = [
    kubernetes_manifest.postgresql_svc,
    kubernetes_manifest.postgresql_secret,
    kubernetes_manifest.postgresql_configmap
  ]
}

resource "kubernetes_manifest" "postgresql_svc" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/postgresql/postgresql-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "postgresql_secret" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/postgresql/postgresql-secret.yaml.tpl", {
    env                              = var.env,
    sys_name                         = var.sys_name,
    base64_postgresql_admin          = base64encode(var.postgresql_admin),
    base64_postgresql_admin_password = base64encode(var.postgresql_admin_password)
  }))
}

resource "kubernetes_manifest" "postgresql_configmap" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/postgresql/postgresql-configmap.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "postgresql_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/postgresql/postgresql-network-policy.yaml.tpl", {
    env                   = var.env,
    sys_name              = var.sys_name,
    iac_subnet_cidr_block = var.iac_subnet_cidr_block
  }))
}

# Internal application
## batch-analyzer
resource "kubernetes_manifest" "batch_analyzer_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/batch-analyzer/batch-analyzer-dply.yaml.tpl", {
    env                        = var.env,
    sys_name                   = var.sys_name,
    ns_sample_value            = var.ns_sample_value,
    batch_analyzer_key_command = var.batch_analyzer_key_command,
    aws_account_id             = var.aws_account_id,
    domain                     = var.domain
  }))

  depends_on = [
    kubernetes_manifest.batch_analyzer_secret
  ]
}

resource "kubernetes_manifest" "batch_analyzer_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/batch-analyzer/batch-analyzer-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "batch_analyzer_secret" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/batch-analyzer/batch-analyzer-secret.yaml.tpl", {
    env                     = var.env,
    sys_name                = var.sys_name,
    data_controller_api_key = base64encode(var.bacth_analyzer_data_controller_api_key)
  }))
}

resource "kubernetes_manifest" "batch_analyzer_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/batch-analyzer/batch-analyzer-network-policy.yaml.tpl", {
    env                   = var.env,
    sys_name              = var.sys_name,
    iac_subnet_cidr_block = var.iac_subnet_cidr_block
  }))
}

##Grafana
resource "kubernetes_manifest" "grafana_stfs" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/grafana/grafana-stfs.yaml.tpl", {
    env             = var.env,
    sys_name        = var.sys_name,
    ns_sample_value = var.ns_sample_value,
    ecr_url         = var.ecr_grafana_url
  }))

  depends_on = [
    kubernetes_manifest.grafana_svc
  ]
}

resource "kubernetes_manifest" "grafana_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/grafana/grafana-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "grafana_tgb" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/grafana/grafana-tgb.yaml.tpl", {
    grafana_tg_arn = var.grafana_tg_arn,
    env            = var.env,
    sys_name       = var.sys_name,
    pub_sg         = data.aws_security_group.eks_ingress_sg.id
  }))

  depends_on = [
    kubernetes_manifest.grafana_svc
  ]
}

resource "kubernetes_manifest" "grafana_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/grafana/grafana-network-policy.yaml.tpl", {
    env                   = var.env,
    sys_name              = var.sys_name,
    iac_subnet_cidr_block = var.iac_subnet_cidr_block
  }))
}

resource "kubernetes_manifest" "data_filtering_api_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/data-filtering-api/data-filtering-api-network-policy.yaml.tpl", {
    env                   = var.env,
    sys_name              = var.sys_name,
    iac_subnet_cidr_block = var.iac_subnet_cidr_block
  }))
}

## servicer console
resource "kubernetes_manifest" "servicer_console_secret" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/servicer-console/servicer-console-secret.yaml.tpl", {
    env                    = var.env,
    sys_name               = var.sys_name,
    keycloak_client_id     = base64encode(var.servicer_console_keycloak_client_id),
    keycloak_client_secret = base64encode(var.servicer_console_keycloak_client_secret)
  }))
}

resource "kubernetes_manifest" "servicer_console_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/servicer-console/servicer-console-dply.yaml.tpl", {
    env                           = var.env,
    sys_name                      = var.sys_name,
    keycloak_endpoint_url         = "https://${var.alb_api_domains.keycloak2}",
    keycloak_realm                = var.sys_name,
    ecr_url                       = var.ecr_servicer_console_url,
    realtime_notification_api_key = var.realtime_notification_api_key,
    domain                        = var.domain
  }))

  depends_on = [
    kubernetes_manifest.servicer_console_secret
  ]
}

resource "kubernetes_manifest" "servicer_console_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/servicer-console/servicer-console-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name,
  }))
}

resource "kubernetes_manifest" "servicer_console_tgb" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/servicer-console/servicer-console-tgb.yaml.tpl", {
    servicer_console_tg_arn = var.servicer_console_tg_arn,
    env                     = var.env,
    sys_name                = var.sys_name,
    pub_sg                  = data.aws_security_group.eks_ingress_sg.id
  }))

  depends_on = [
    kubernetes_manifest.servicer_console_svc
  ]
}

resource "kubernetes_manifest" "servicer_console_network_policy" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/servicer-console/servicer-console-network-policy.yaml.tpl", {
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
    kubernetes_manifest.cluster_autoscaler_role_binding
  ]

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}

## data-filtering-api
resource "kubernetes_manifest" "data_filtering_api_dply" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/data-filtering-api/data-filtering-api-dply.yaml.tpl", {
    env             = var.env,
    sys_name        = var.sys_name,
    ns_sample_value = var.ns_sample_value,
    ecr_url         = var.ecr_data_filtering_api_url,
    domain          = var.domain
  }))

  depends_on = [
    kubernetes_manifest.data_filtering_api_svc
  ]

  field_manager {
    name            = "terraform"
    force_conflicts = true
  }
}

resource "kubernetes_manifest" "data_filtering_api_svc" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/data-filtering-api/data-filtering-api-svc.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "data_filtering_api_secret" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/data-filtering-api/data-filtering-api-secret.yaml.tpl", {
    env                    = var.env,
    sys_name               = var.sys_name,
    base64_backend_api_key = base64encode(var.data_filtering_api_backend_api_key)
  }))
}

## Horizontal pod autoscaler
resource "kubernetes_manifest" "sample_analyzer_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/real-time-analysis-service/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
}

resource "kubernetes_manifest" "realtime_transform_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/realtime-transform/horizontal-pod-autoscaler.yaml.tpl", {
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

resource "kubernetes_manifest" "data_filtering_api_hpa" {
  manifest = yamldecode(templatefile("${path.module}/infra_yaml_tpl/horizontal-pod-autoscaler/data-filtering-api/horizontal-pod-autoscaler.yaml.tpl", {
    env      = var.env,
    sys_name = var.sys_name
  }))
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

## Keycloak Setting
resource "kubernetes_manifest" "keycloak_setting_configmap" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/keycloak/keycloak-setting-configmap.yaml.tpl", {
    env         = var.env,
    sys_name    = var.sys_name
    init_script = indent(4, file("${path.module}/../../externals/keycloak/init.sh"))
  }))
}

resource "kubernetes_manifest" "keycloak_setting_job" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/keycloak/keycloak-setting.yaml.tpl", {
    env             = var.env,
    sys_name        = var.sys_name
    admin_username  = var.keycloak_setting_admin_username
    admin_password  = var.keycloak_setting_admin_password
    new_realm       = var.keycloak_setting_new_realm
    client_id_value = "console"
    client_root_url = var.keycloak_setting_client_root_url
    user_username   = var.keycloak_setting_user_username
    user_password   = var.keycloak_setting_user_password
  }))

  depends_on = [kubernetes_manifest.keycloak_setting_configmap]
}

# PostgreSQL Setting
resource "kubernetes_manifest" "postgres_setting" {
  manifest = yamldecode(templatefile("${path.module}/app_yaml_tpl/postgres/postgres-setting.yaml.tpl", {
    env                      = var.env,
    sys_name                 = var.sys_name
    postgres_setting_ecr_url = var.postgres_setting_ecr_url
  }))
}
