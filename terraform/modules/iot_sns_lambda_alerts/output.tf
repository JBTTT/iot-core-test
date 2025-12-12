output "sns_topic_arn" {
  value = aws_sns_topic.iot_alerts.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.alert_handler.function_name
}

output "iot_rule_name" {
  value = aws_iot_topic_rule.threshold_rule.name
}

output "dashboard_url" {
  value = "https://console.aws.amazon.com/cloudwatch/home#dashboards:name=${var.prefix}-${var.env}-iot-dashboard"
}
