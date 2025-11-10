data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iot_logging_options" "iot_logging" {
  default_log_level = "INFO"
  role_arn  = aws_iam_role.iot_logging_role.arn
}

# 公式リンク参照
# https://docs.aws.amazon.com/ja_jp/iot/latest/developerguide/configure-logging.html
resource "aws_iam_role" "iot_logging_role" {
  name = "themis2-${var.env}-iot-logging-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "iot.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "iot_logging_policy" {
  name = "themis2-${var.env}-iot-logging-policy"
  role = aws_iam_role.iot_logging_role.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
		"logs:CreateLogGroup",
		"logs:CreateLogStream",
		"logs:PutLogEvents",
		"logs:PutMetricFilter",
		"logs:PutRetentionPolicy",
		"iot:GetLoggingOptions",
		"iot:SetLoggingOptions",
		"iot:SetV2LoggingOptions",
		"iot:GetV2LoggingOptions",
		"iot:SetV2LoggingLevel",
		"iot:ListV2LoggingLevels",
		"iot:DeleteV2LoggingLevel"
      ],
      "Resource": "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:AWSIotLogsV2:*"
    }
  ]
}
POLICY
}
