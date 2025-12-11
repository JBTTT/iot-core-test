resource "aws_cloudwatch_dashboard" "iot_dashboard" {
  dashboard_name = "${var.prefix}-${var.env}-iot-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            ["IoT/Anomalies", "AnomalyDetected", "Environment", var.env]
          ],
          "period": 300,
          "stat": "Sum",
          "title": "Total IoT Anomalies (5-min window)"
        }
      },
      {
        "type": "metric",
        "width": 12,
        "height": 6,
        "properties": {
          "metrics": [
            ["IoT/Anomalies", "AnomalyDetected", "Environment", var.env, "DeviceID", "cet11-grp1-dev-device"]
          ],
          "period": 300,
          "stat": "Sum",
          "title": "Anomalies per Device"
        }
      }
    ]
  })
}
