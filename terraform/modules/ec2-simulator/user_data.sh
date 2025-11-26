#!/bin/bash

yum update -y
yum install -y python3 pip git

pip3 install AWSIoTPythonSDK

mkdir -p /iot
cd /iot

cat <<EOF > simulator.py
import time
import json
import random
from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient

mqttc = AWSIoTMQTTClient("iot-simulator-client")
mqttc.configureEndpoint("${iot_endpoint}", 8883)
mqttc.configureCredentials("/iot/AmazonRootCA1.pem", "/iot/private.key", "/iot/certificate.pem")

mqttc.connect()
print("Simulator Connected to AWS IoT Core")

while True:
    payload = {
        "device_id": "${prefix}-${env}-device",
        "temperature": round(random.uniform(20.0, 45.0), 2),
        "humidity": round(random.uniform(40.0, 80.0), 2),
        "timestamp": int(time.time())
    }

    topic = "${prefix}/${env}/data"
    mqttc.publish(topic, json.dumps(payload), 1)
    print("Published:", payload)

    time.sleep(5)
EOF

# Download CA cert
wget https://www.amazontrust.com/repository/AmazonRootCA1.pem -O /iot/AmazonRootCA1.pem

# These parameters must be stored in SSM by Terraform or manually uploaded
aws ssm get-parameter --name "/iot/${prefix}/${env}/cert" --with-decryption --query "Parameter.Value" --output text > /iot/certificate.pem
aws ssm get-parameter --name "/iot/${prefix}/${env}/key"  --with-decryption --query "Parameter.Value" --output text > /iot/private.key

python3 /iot/simulator.py > /iot/log.txt 2>&1 &
