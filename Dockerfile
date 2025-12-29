FROM python:3.11-slim

WORKDIR /app

COPY simulator.py .

RUN pip install --no-cache-dir boto3 paho-mqtt

CMD ["python", "simulator.py"]

