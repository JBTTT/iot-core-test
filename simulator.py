import json
import time
import random
import ssl
from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient

# Configuration injected by user_data.sh
ENDPOINT = "${iot_endpoint}"
PREFIX = "${prefix}"
ENV = "${env}"

CLIENT_ID = f"{PREFIX}-{ENV}-simulator"
TOPIC = f"{PREFIX}/{ENV}/data"

# Setup MQTT client
client = AWSIoTMQTTClient(CLIENT_ID)
client.configureEndpoint(ENDPOINT, 8883)
client.configureCredentials(
    "/iot/AmazonRootCA1.pem",
    "/iot/private.key",
    "/iot/certificate.pem"
)
client.configureOfflinePublishQueueing(-1)  # Infinite offline queueing
client.configureConnectDisconnectTimeout(10)
client.configureMQTTOperationTimeout(5)

print("Connecting to AWS IoT Core...")
client.connect()
print(f"Connected to AWS IoT Core endpoint: {ENDPOINT}")
print(f"Publishing to topic: {TOPIC}")

# Continuous telemetry loop
while True:
    payload = {
        "device_id": f"{PREFIX}-{ENV}-device",
        "temperature": round(random.uniform(20.0, 45.0), 2),
        "humidity": round(random.uniform(40.0, 80.0), 2),
        "pressure": round(random.uniform(990.0, 1025.0), 2),
        "battery": random.randint(60, 100),
        "timestamp": int(time.time())
    }

    client.publish(TOPIC, json.dumps(payload), 1)
    print("Published:", payload)

    time.sleep(5)
