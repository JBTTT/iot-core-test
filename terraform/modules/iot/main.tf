#############################################
# IoT MODULE — cet11-grp1
#############################################

resource "aws_iot_thing" "device" {
  name = "${var.prefix}-${var.env}-device"
}

resource "aws_iot_policy" "policy" {
  name = "${var.prefix}-${var.env}_iot_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow"
      Action = [
        "iot:Connect",
        "iot:Publish",
        "iot:Subscribe",
        "iot:Receive"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iot_certificate" "cert" {
  active = true
}

resource "aws_iot_policy_attachment" "attach_policy" {
  policy = aws_iot_policy.policy.name
  target = aws_iot_certificate.cert.arn
}

resource "aws_ssm_parameter" "cert" {
  name  = "/iot/${var.prefix}/${var.env}/cert"
  type  = "SecureString"
  value = aws_iot_certificate.cert.certificate_pem
}

resource "aws_ssm_parameter" "key" {
  name  = "/iot/${var.prefix}/${var.env}/key"
  type  = "SecureString"
  value = aws_iot_certificate.cert.private_key
}

resource "aws_iot_topic_rule" "topic_rule" {
  name        = "${var.prefix}-${var.env}_iot_rule"
  description = "IoT rule placeholder"
  enabled     = true

  sql         = "SELECT * FROM '${var.prefix}/${var.env}/data'"
  sql_version = "2016-03-23"
}

