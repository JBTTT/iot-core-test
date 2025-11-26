resource "aws_iot_topic_rule" "cet11_grp1_rule" {
  name        = "${var.prefix}-${var.env}-iot-rule"
  description = "IoT rule placeholder for future Lambda integration"
  enabled     = true

  # Will be updated later when Lambda is plugged in
  sql         = "SELECT * FROM '${var.prefix}/${var.env}/data'"
  sql_version = "2016-03-23"

  # No lambda action for now; rule is created as a placeholder
}

# IoT Thing (optional but included for simulation readiness)
resource "aws_iot_thing" "device" {
  name = "${var.prefix}-${var.env}-device"
}

resource "aws_iot_policy" "policy" {
  name = "${var.prefix}-${var.env}-iot-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action: [
          "iot:Connect",
          "iot:Publish",
          "iot:Subscribe",
          "iot:Receive"
        ],
        Resource: "*"
      }
    ]
  })
}

resource "aws_iot_certificate" "cert" {
  active = true
}

resource "aws_iot_policy_attachment" "attach" {
  policy = aws_iot_policy.policy.name
  target = aws_iot_certificate.cert.arn
}
