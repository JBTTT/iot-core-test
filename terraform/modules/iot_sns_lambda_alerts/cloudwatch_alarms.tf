resource "aws_cloudwatch_metric_alarm" "anomaly_spike" {
  alarm_name          = "${var.prefix}-${var.env}-anomaly-spike"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  period              = 600 # 10 minutes
  threshold           = 3   # more than 3 anomalies in 10 minutes
  metric_name         = "AnomalyDetected"
  namespace           = "IoT/Anomalies"
  statistic           = "Sum"

  alarm_actions = [aws_sns_topic.iot_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "no_anomalies" {
  alarm_name          = "${var.prefix}-${var.env}-no-anomalies"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  period              = 3600 # 1 hour
  threshold           = 1
  metric_name         = "AnomalyDetected"
  namespace           = "IoT/Anomalies"
  statistic           = "Sum"

  treat_missing_data = "breaching"

  alarm_actions = [aws_sns_topic.iot_alerts.arn]
}
