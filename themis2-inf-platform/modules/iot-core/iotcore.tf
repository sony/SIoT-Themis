# iot coreでAmazonルートCA認証局を利用して作成する場合
# https://docs.aws.amazon.com/ja_jp/iot/latest/developerguide/device-certs-create.html
# terraform
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iot_certificate
# 作成後、Amazon CLIで情報の取得が必要。
# https://awscli.amazonaws.com/v2/documentation/api/latest/reference/iot/create-keys-and-certificate.html

resource "aws_iot_certificate" "themis2_iot_certificates" {
  active = true
}

# 受信機をCountを利用して複数登録
# Countは変動
resource "aws_iot_thing" "themis2_eltres_things" {
  count = 1
  name  = "${var.sys_name}-${var.env}-eltres-receiver-${count.index + 1}"
}

resource "aws_iot_thing_group" "themis2_eltres_iot_group" {
  name = "${var.sys_name}-${var.env}-eltres-iot-group"
  properties {
    description = "ELTRES Receiver Group"
  }
  tags = {
    name                = "${var.sys_name}-${var.env}-eltres-iot-group"
    environment         = "${var.env}"
    systemname          = "${var.sys_name}"
    create-by-terraform = "true"
  }
}

resource "aws_iot_thing_group_membership" "themis2_eltres_iot_group_membership" {
  count            = 1
  thing_name       = aws_iot_thing.themis2_eltres_things[count.index].name
  thing_group_name = aws_iot_thing_group.themis2_eltres_iot_group.name
}

# Policy Create
resource "aws_iot_policy" "themis2_iot_policy" {
  name   = "${var.sys_name}-${var.env}-eltres-iot-policy"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "iot:*",
      "Resource": "*"
    }
  ]
}
POLICY
}

# Policy Attach
resource "aws_iot_policy_attachment" "themis2_policy_attach" {
  policy = aws_iot_policy.themis2_iot_policy.name
  target = aws_iot_certificate.themis2_iot_certificates.arn
}

resource "aws_iot_thing_principal_attachment" "themis2_eltres_attach" {
  count     = 1
  thing     = aws_iot_thing.themis2_eltres_things[count.index].name
  principal = aws_iot_certificate.themis2_iot_certificates.arn
}

# ルール用ロール & ポリシー
resource "aws_iam_role" "themis2_iot_role" {
  name = "${var.sys_name}-${var.env}-IotRole"
  path = "/service-role/"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "iot.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# 既存のカスタマー管理ポリシー
resource "aws_iam_policy" "themis2_iot_republish_policy" {
  name   = "${var.sys_name}-${var.env}-eltres-iot-republish-policy"
  path   = "/service-role/"
  policy = jsonencode(
    {
      Version   = "2012-10-17",
      Statement = [
        {
          Action   = "iot:Publish"
          Effect   = "Allow"
          Resource = "arn:aws:iot:ap-northeast-1:${var.aws_account_id}:topic/eltres/global/payload-with-principalId"
        }
      ]
    }
  )
}

# ロールへのアタッチ
resource "aws_iam_role_policy_attachment" "themis2_iot_role_attach" {
  role       = aws_iam_role.themis2_iot_role.name
  policy_arn = aws_iam_policy.themis2_iot_republish_policy.arn
}

# ルールの作成
resource "aws_iot_topic_rule" "rule" {
  description = "principalIdが含まれたpayload情報取得用"
  enabled     = true
  name        = "${var.sys_name}_${var.env}_rule_get_payload_principalId"
  sql         = "SELECT *, principal() AS principalId FROM 'eltres/+/+/+/rx/payload'"
  sql_version = "2016-03-23"
  tags        = {}

  republish {
    qos      = 0
    role_arn = aws_iam_role.themis2_iot_role.arn
    topic    = "eltres/global/payload-with-principalId"
  }
}
