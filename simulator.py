import json
import time
import random
from AWSIoTPythonSDK.MQTTLib import AWSIoTMQTTClient

# --------------------------------------------------------------------
# Configuration injected automatically from user_data.sh via Terraform
# --------------------------------------------------------------------
ENDPOINT = "${iot_endpoint}"
PREFIX = "${prefix}"
ENV = "${env}"

CLIENT_ID = f"{PREFIX}-{ENV}-simulator"
TOPIC = f"{PREFIX}/{ENV}/data"

# -----------------------------
# Threshold values (configurable)
# -----------------------------
THRESHOLDS = {
    "temperature_min": 25,
    "temperature_max": 40,

    "humidity_min": 40,
    "humidity_max": 80,

    "pressure_min": 990,
    "pressure_max": 1025,

    "battery_min": 60,
    "battery_max": 100
}

# Compute 80% upper thresholds
THRESHOLDS_80 = {
    "temperature_80": THRESHOLDS["temperature_max"] * 0.80,
    "humidity_80":    THRESHOLDS["humidity_max"] * 0.80,
    "pressure_80":    THRESHOLDS["pressure_max"] * 0.80,
    "battery_80":     THRESHOLDS["battery_max"] * 0.80,
}

# --------------------------------------------------------------------
# Setup MQTT Client
# --------------------------------------------------------------------
client = AWSIoTMQTTClient(CLIENT_ID)
client.configureEndpoint(ENDPOINT, 8883)
client.configureCredentials(
    "/iot/AmazonRootCA1.pem",
    "/iot/private.key",
    "/iot/certificate.pem"
)
client.configureOfflinePublishQueueing(-1)  # infinite queueing
client.configureConnectDisconnectTimeout(10)
client.configureMQTTOperationTimeout(5)

print("Connecting to AWS IoT Core...")
client.connect()
print(f"Connected! Publishing to: {TOPIC}")
print("Starting telemetry simulation...\n")

# --------------------------------------------------------------------
# Function to check threshold breaches
# --------------------------------------------------------------------
def detect_thresholds(sensor):
    alerts = {}

    # Temperature
    alerts["temperature_low"]  = sensor["temperature"] < THRESHOLDS["temperature_min"]
    alerts["temperature_high"] = sensor["temperature"] > THRESHOLDS_80["temperature_80"]

    # Humidity
    alerts["humidity_low"]  = sensor["humidity"] < THRESHOLDS["humidity_min"]
    alerts["humidity_high"] = sensor["humidity"] > THRESHOLDS_80["humidity_80"]

    # Pressure
    alerts["pressure_low"]  = sensor["pressure"] < THRESHOLDS["pressure_min"]
    alerts["pressure_high"] = sensor["pressure"] > THRESHOLDS_80["pressure_80"]

    # Battery
    alerts["battery_low"]  = sensor["battery"] < THRESHOLDS["battery_min"]
    alerts["battery_high"] = sensor["battery"] > THRESHOLDS_80["battery_80"]

    # Derived field: True if ANY threshold was breached
    alerts["threshold_breached"] = any(alerts.values())

    return alerts


# --------------------------------------------------------------------
# Main Loop
# --------------------------------------------------------------------
while True:

    # Random simulated telemetry values
    sensor = {
        "device_id": f"{PREFIX}-{ENV}-device",
        "temperature": round(random.uniform(20.0, 45.0), 2),
        "humidity": round(random.uniform(40.0, 85.0), 2),
        "pressure": round(random.uniform(985.0, 1030.0), 2),
        "battery": random.randint(50, 100),
        "timestamp": int(time.time())
    }

    # Check threshold violations
    alerts = detect_thresholds(sensor)

    # Merge alerts into final payload
    payload = {**sensor, **alerts}

    # Publish to IoT Core
    client.publish(TOPIC, json.dumps(payload), 1)

    print("Published:", json.dumps(payload, indent=2))

    if alerts["threshold_breached"]:
        print("⚠️  ALERT: Threshold breached!\n")

    time.sleep(5)
