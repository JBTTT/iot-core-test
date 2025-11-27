import json
import time
import random
from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient

# Configuration injected by user_data.sh
ENDPOINT = "${iot_endpoint}"
PREFIX = "${prefix}"
ENV = "${env}"

CLIENT_ID = f"{PREFIX}-{ENV}-simulator"

DATA_TOPIC = f"{PREFIX}/{ENV}/data"
ALERT_TOPIC = f"{PREFIX}/{ENV}/alert"

# Thresholds
TEMP_HIGH = 40.0          # Degrees Celsius
TEMP_LOW = 25.0           # Degrees Celsius
HUMIDITY_HIGH = 80.0      # %
HUMIDITY_LOW = 40.0       # %
BATTERY_LOW = 30          # %
PRESSURE_LOW = 995.0      # hPa
PRESSURE_HIGH = 1020.0    # hPa

# Setup MQTT client
client = AWSIoTMQTTClient(CLIENT_ID)
client.configureEndpoint(ENDPOINT, 8883)
client.configureCredentials(
    "/iot/AmazonRootCA1.pem",
    "/iot/private.key",
    "/iot/certificate.pem"
)
client.configureOfflinePublishQueueing(-1)
client.configureConnectDisconnectTimeout(10)
client.configureMQTTOperationTimeout(5)

print("Connecting to AWS IoT Core...")
client.connect()
print(f"Connected to {ENDPOINT}")
print(f"Data Topic: {DATA_TOPIC}")
print(f"Alert Topic: {ALERT_TOPIC}")

def check_thresholds(payload):
    alerts = []

    if payload["temperature"] > TEMP_HIGH:
        alerts.append(f"High temperature detected: {payload['temperature']}°C")

    if payload["temperature"] < TEMP_LOW:
        alerts.append(f"Low temperature detected: {payload['temperature']}°C")

    if payload["humidity"] > HUMIDITY_HIGH:
        alerts.append(f"High humidity detected: {payload['humidity']}%")

    if payload["humidity"] < HUMIDITY_LOW:
        alerts.append(f"Low humidity detected: {payload['humidity']}%")

    if payload["battery"] < BATTERY_LOW:
        alerts.append(f"Low battery level: {payload['battery']}%")

    if payload["pressure"] < PRESSURE_LOW:
        alerts.append(f"Low pressure: {payload['pressure']} hPa")

    if payload["pressure"] > PRESSURE_HIGH:
        alerts.append(f"High pressure: {payload['pressure']} hPa")

    return alerts


# Continuous telemetry loop
while True:
    payload = {
        "device_id": f"{PREFIX}-{ENV}-device",
        "temperature": round(random.uniform(20.0, 45.0), 2),
        "humidity": round(random.uniform(35.0, 90.0), 2),
        "pressure": round(random.uniform(985.0, 1030.0), 2),
        "battery": random.randint(20, 100),
        "timestamp": int(time.time())
    }

    # Publish normal data
    client.publish(DATA_TOPIC, json.dumps(payload), 1)
    print("Published Data:", payload)

    # Threshold evaluation
    alerts = check_thresholds(payload)

    if alerts:
        alert_payload = {
            "device_id": payload["device_id"],
            "alerts": alerts,
            "timestamp": payload["timestamp"]
        }

        client.publish(ALERT_TOPIC, json.dumps(alert_payload), 1)
        print("⚠️ ALERT DETECTED:", alert_payload)

    time.sleep(5)
