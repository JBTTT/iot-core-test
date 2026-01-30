# AWS IoT Core Test – Telemetry Simulator & Ingestion Platform

This repository contains a **Terraform-managed AWS IoT Core architecture** with a **Python-based telemetry simulator** that can run in **multiple execution environments**:

- **EC2 (VM-based simulator)**
- **Containerized runtime (Docker, ECS Fargate–ready)**

The project is designed to **simulate IoT device telemetry**, validate AWS IoT Core ingestion, test rule-based routing, and observe downstream processing such as storage and alerting.

---

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Execution Models](#execution-models)
  - [EC2-Based Simulator](#1-ec2-based-simulator)
  - [Containerized Simulator (Docker / ECS)](#2-containerized-simulator-docker--ecs)
- [Simulator](#simulator)
- [AWS Components](#aws-components)
  - [AWS IoT Core](#aws-iot-core)
  - [Amazon S3](#amazon-s3)
  - [AWS Lambda](#aws-lambda)
  - [Amazon SNS](#amazon-sns)
- [IoT Rules & Data Flow](#iot-rules--data-flow)
- [Repository Structure](#repository-structure)
- [Terraform & Environments](#terraform--environments)
- [CI/CD](#cicd)
- [Running the Simulator](#running-the-simulator)
  - [EC2 (Automatic)](#ec2-automatic)
  - [Docker (Manual / ECS)](#docker-manual--ecs)
- [Telemetry Format](#telemetry-format)
- [Security Model](#security-model)
- [Operations & Cleanup](#operations--cleanup)
- [Scalability & Cost Notes](#scalability--cost-notes)
- [Summary](#summary)

---

## Overview

The purpose of this project is to provide a **reproducible IoT ingestion test environment** on AWS. It focuses on:

- Secure MQTT ingestion using **AWS IoT Core**
- Simulated device telemetry using Python
- Infrastructure provisioning using **Terraform**
- Automated lifecycle management via **GitHub Actions**
- Comparison of **EC2 vs container-based simulation**

The same simulator codebase can be reused across environments and execution models without modification.

---

## Architecture

At a high level, the system consists of **telemetry producers**, **AWS IoT Core**, and **downstream consumers**.

Telemetry Producers  
- EC2 Instance (Python simulator)  
- Docker Container (ECS Fargate compatible)  

MQTT (TLS, X.509) → AWS IoT Core  
- MQTT Broker  
- Rules Engine  
  - Persist telemetry to S3  
  - Trigger Lambda on conditions → SNS Alerts  

The design intentionally decouples **message ingestion** from **processing**, ensuring that ingestion remains resilient even if downstream systems fail.

---

## Execution Models

### 1. EC2-Based Simulator

- Python simulator runs directly on an EC2 instance
- Instance is provisioned and bootstrapped via Terraform
- Startup behavior controlled through `user_data.sh`
- Suitable for:
  - Long-running tests
  - Continuous background traffic
  - Easier debugging via SSH

---

### 2. Containerized Simulator (Docker / ECS)

- Same simulator packaged using `Dockerfile`
- Can run locally with Docker or in ECS Fargate
- Stateless execution model
- Suitable for:
  - Burst traffic
  - Parallel simulations
  - Short-lived load tests
  - CI-triggered tasks

---

## Simulator

### simulator.py

The simulator is a Python script responsible for:

- Connecting to AWS IoT Core via MQTT
- Authenticating using X.509 certificates
- Generating synthetic telemetry data
- Publishing telemetry at regular intervals
- Handling reconnects and transient failures

The simulator does **not** depend on AWS credentials. All authentication is handled via IoT certificates.

---

## AWS Components

### AWS IoT Core

- Acts as the secure MQTT endpoint
- Authenticates devices via certificates
- Routes messages using IoT Rules
- Scales independently of compute

---

### Amazon S3

- Stores raw telemetry payloads
- Used as a durable, low-cost archive
- Enables offline analysis, replay, or analytics tooling

---

### AWS Lambda

- Triggered by IoT Rules
- Executes conditional logic (e.g. threshold checks)
- Decouples real-time processing from ingestion

---

### Amazon SNS

- Sends notifications (e.g. email alerts)
- Allows fan-out to multiple subscribers
- Keeps alerting asynchronous

---

## IoT Rules & Data Flow

1. Simulator publishes MQTT message  
2. AWS IoT Core authenticates and ingests  
3. IoT Rules evaluate message  
4. Messages are persisted to S3  
5. Optional Lambda invocation  
6. SNS alerts delivered  

**Key principle:** ingestion is never blocked by downstream processing.

---

## Repository Structure

```
.
├── .github/workflows/           # CI/CD pipelines
├── terraform/                   # Terraform IaC
├── simulator.py                 # Python MQTT simulator
├── Dockerfile                   # Container build definition
├── user_data.sh                 # EC2 bootstrap script
├── bootstrap-run.sh             # Terraform bootstrap helper
├── cleanup.sh                   # Resource teardown
├── cleanup_tf_backend_v2.sh     # Terraform backend cleanup
├── git-sync.sh                  # Utility script
└── README.md
```

---

## Terraform & Environments

Terraform is used to manage **all AWS resources**, including:

- AWS IoT Core policies and rules
- Certificates and attachments
- EC2 instances
- IAM roles and permissions
- S3 buckets
- Lambda functions
- SNS topics

The repository supports **environment isolation** (e.g. dev / prod) through separate Terraform state and resource naming.

---

## CI/CD

GitHub Actions are used to:

- Validate Terraform code
- Generate Terraform plans
- Apply infrastructure changes
- Package and deploy Lambda code

This ensures infrastructure changes are repeatable and auditable.

---

## Running the Simulator

### EC2 (Automatic)

1. Apply Terraform
2. EC2 instance boots
3. `user_data.sh` installs dependencies
4. Simulator starts automatically

---

### Docker (Manual / ECS)

Build and run locally:

```bash
docker build -t iot-simulator .
docker run iot-simulator
```

The same image can be deployed to ECS Fargate.

---

## Telemetry Format

Example telemetry payload:

```json
{
  "device_id": "device-001",
  "timestamp": "2026-01-30T15:42:21Z",
  "metrics": {
    "temperature": 72.5,
    "humidity": 41.2,
    "pressure": 1013.4
  },
  "sequence": 18432
}
```

MQTT topic structure:

```
iot/devices/{device_id}/telemetry
```

---

## Security Model

- Mutual TLS authentication
- X.509 certificates per environment
- Least-privilege IoT policies
- IAM roles separated by function
- No static secrets embedded in code

---

## Operations & Cleanup

### Cleanup Resources

```bash
./cleanup.sh
```

### Terraform Backend Cleanup

```bash
./cleanup_tf_backend_v2.sh
```

Used for state reset or environment reinitialization.

---

## Scalability & Cost Notes

- **EC2**: fixed cost, ideal for continuous load
- **Containers**: pay-per-use, ideal for burst testing
- **AWS IoT Core**: scales automatically, cost based on message volume

---

## Summary

This repository provides:

- A realistic AWS IoT ingestion architecture
- A portable Python-based simulator
- Two execution models using the same code
- Full Terraform-based lifecycle management
- CI/CD-driven infrastructure discipline

Suitable for experimentation, validation, load testing, and reference implementations.
