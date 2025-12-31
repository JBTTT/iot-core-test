# IoT Simulator Infrastructure (Dev + Prod)

**IoT Load & Telemetry Simulation with AWS IoT Core + Terraform + GitHub Actions CI/CD**

This repository contains a **fully automated multi-environment AWS IoT Core architecture** designed to simulate IoT telemetry data, store raw data, trigger alert workflows, and integrate with CI/CD pipelines for infrastructure and Lambda deployment.

---

## 🧩 Table of Contents

1. [Overview](#overview)  
2. [Architecture & Services Included](#architecture--services-included)  
3. [Data Flow](#data-flow)  
4. [CI/CD Flow](#cicd-flow)  
5. [Environments](#environments)  
6. [Component Breakdown](#component-breakdown)  
7. [How to Use / Deploy](#how-to-use--deploy)  
8. [Scripts & Utilities](#scripts--utilities)  
9. [License](#license)

---

## 📌 Overview

This project provides:

- **Multi-environment AWS IoT Core setup** (dev + prod)  
- **EC2-based IoT simulation** running a Python MQTT publisher  
- **AWS IoT Core with Rules Engine** for data routing and processing  
- **DynamoDB or S3** as telemetry data repositories  
- **Lambda functions** for real-time alert handling  
- **SNS email alerts** for threshold breaches  
- **GitHub Actions CI/CD workflows** to validate, plan, and apply infrastructure changes

---

## 🏗 Architecture & Services Included

The following AWS services are used:

| Service | Purpose |
|---------|---------|
| **AWS IoT Core** | MQTT broker and rules engine for ingesting device telemetry |
| **EC2 Instances** | Simulators publish telemetry to IoT Core |
| **S3 Buckets** | Raw telemetry storage |
| **AWS Lambda** | Processes threshold breaches |
| **SNS (Simple Notification Service)** | Sends alert emails |
| **Terraform** | Infrastructure provisioning |
| **GitHub Actions** | CI/CD pipelines |
| **SSM (Parameter Store)** | Secure storage for certificates or config |

---

## 🔁 Data Flow

Below is the **end-to-end flow** of telemetry and alert handling in the system:

EC2 Simulator
(Python MQTT Publisher)
│
▼ (MQTT Publish)
AWS IoT Core
(Message Broker + Rules Engine)
├── Rule A ─▶ Raw Telemetry ▶ S3 Bucket
│
└── Rule B (Conditional on thresholds)
▼
AWS Lambda
(Threshold Alert Handler)
│
▼
SNS Topic
│
▼
Email Notification (User)


### Flow Description

1. **Telemetry Generation**  
   A Python script (`simulator.py`) on an EC2 instance sends MQTT messages to AWS IoT Core with random sensor data.

2. **AWS IoT Rule Engine**  
   - **Rule A** always stores incoming telemetry into an S3 bucket for raw data archiving.  
   - **Rule B** triggers only on threshold violation (e.g., temperature too high/low) and invokes a Lambda function.

3. **Lambda: Alert Handler**  
   Parses the telemetry event and publishes notifications to an SNS topic.

4. **SNS Email Delivery**  
   Sends an alert email to subscribed addresses with the telemetry detail.

*(Diagram adapted from repository diagram)* :contentReference[oaicite:0]{index=0}

---

## 🚀 CI/CD Flow

Automated workflows are defined in `.github/workflows`:

### **1. Terraform Validation & Plan**

- Format and validate Terraform code
- Run `terraform fmt`, `terraform validate`
- Generate a plan for infrastructure changes

### **2. Terraform Apply — Dev Environment**

On push to the `dev` branch:

- Automatically apply Terraform changes to the **development AWS environment**
- Build and package lambda artifacts before deployment

### **3. Terraform Apply — Prod Environment (Gated)**

- Prod deploy is gated via pull request or manual trigger
- Ensures changes to production require review

### GitHub Actions Lifecycle

GitHub Push
▼
Workflow Trigger (.yml)
│
├── Lint / Validate / Terraform Plan
│
├── Build Lambda Artifacts
│
└── Terraform Apply (dev or prod)


*(Derived from repo workflows)* :contentReference[oaicite:1]{index=1}

---

## 🧪 Environments

| Environment | VPC | Simulator Instance | IoT Core | Data Store | Alerts |
|-------------|-----|-------------------|-----------|-------------|--------|
| **Dev** | VPC (10.10.0.0/16) | EC2 Simulator | MQTT → Dev | S3 DynamoDB Dev | SNS Dev |
| **Prod** | VPC (10.20.0.0/16) | EC2 Simulator | MQTT → Prod | S3 DynamoDB Prod | SNS Prod |

*(Based on Terraform definitions and README diagram)* :contentReference[oaicite:2]{index=2}

---

## 🧱 Component Breakdown

### 📦 Terraform

Under `terraform/`, there are modules for:

- **IoT Core config**
- **Lambda packaging / deployment**
- **VPC + EC2 simulator**
- **S3 buckets**
- **SNS + IAM roles**

Terraform uses **state isolation per environment** and is designed to support parallel dev/prod lifecycles.

---

## ⚙️ Scripts & Utilities

| Script | Purpose |
|--------|---------|
| **bootstrap-run.sh** | Initial bootstrap provisioning |
| **cleanup.sh** | Removes resources after testing |
| **cleanup_tf_backend_v2.sh** | Cleans Terraform backend state |
| **git-sync.sh** | Synchronizes git across environments |
| **simulator.py** | Python MQTT publisher simulator |
| **user_data.sh** | EC2 instance provisioning userdata |

---

## 📦 How to Use / Deploy

### 1. **Clone Repo**

```bash
git clone https://github.com/JBTTT/iot-core-test.git
cd iot-core-test

2. Configure AWS Credentials

Export AWS environment variables:

export AWS_ACCESS_KEY_ID=<KEY>
export AWS_SECRET_ACCESS_KEY=<SECRET>
export AWS_DEFAULT_REGION=us-east-1

3. Bootstrap Dev Environment
./bootstrap-run.sh dev

4. Push to GitHub — CI/CD Takes Over

Once pushed:

Dev deploy runs automatically

Prod requires a pull request review

5. Validate IoT Functionality

Check S3 for raw telemetry

Simulate threshold breach via simulator

Validate email alerts from SNS topic

📝 License

