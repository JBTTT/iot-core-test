import boto3
import json
import os

cloudwatch = boto3.client("cloudwatch")
sns = boto3.client("sns")

def lambda_handler(event, context):

    device_id = event.get("device_id", "unknown")
    
    # Determine triggered alert keys
    alert_keys = [k for k, v in event.items() if isinstance(v, bool) and v is True]

    # 1️⃣ Publish CloudWatch Metric: AnomalyDetected = 1
    cloudwatch.put_metric_data(
        Namespace="IoT/Anomalies",
        MetricData=[
            {
                "MetricName": "AnomalyDetected",
                "Dimensions": [
                    {"Name": "Environment", "Value": os.environ["ENV"]},
                    {"Name": "DeviceID", "Value": device_id}
                ],
                "Value": 1,
                "Unit": "Count"
            }
        ]
    )

    # 2️⃣ Send SNS Notification
    sns.publish(
        TopicArn=os.environ["SNS_TOPIC_ARN"],
        Subject=f"IoT Threshold Alert - {os.environ['ENV']}",
        Message=json.dumps({
            "prefix": os.environ["PREFIX"],
            "env": os.environ["ENV"],
            "device_id": device_id,
            "alerts": alert_keys,
            "event": event
        }, indent=2)
    )

    return {
        "status": "OK",
        "alerts": alert_keys
    }

