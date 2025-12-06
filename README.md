# cet11-grp1 IoT Simulator Infrastructure (Dev + Prod)

This repository contains a fully automated, multi-environment AWS IoT Core architecture with:
- Separate **dev** and **prod** environments
- Independent VPCs, subnets, security groups
- IoT Things, certificates, policies, SSM parameters
- DynamoDB tables for telemetry storage
- EC2 IoT Simulator instances (Python MQTT device)
- GitHub Actions CI/CD pipelines (Terraform)
- Environment isolation and state separation

Region used: **us-east-1**

---

# 🏗 Architecture Overview

            +---------------------------+
           |       GitHub Repo         |
           +------------+--------------+
                        |
                        v
           +---------------------------+
           |       GitHub Actions      |
           | (CI: fmt/validate/plan)   |
           | (CD: dev auto, prod gated)|
           +------------+--------------+
                        |
                        v
           +------------+--------------+
           |     Terraform Apply       |
           +------------+--------------+
                        |
   ----------------------------------------------------------
   |                                                        |
   v                                                        v

+---------------------------+         +---------------------------+
|   DEV ENVIRONMENT         |         |   PROD ENVIRONMENT        |
+---------------------------+         +---------------------------+
| VPC (10.10.0.0/16)        |         | VPC (10.20.0.0/16)        |
| Subnet (10.10.1.0/24)     |         | Subnet (10.20.1.0/24)     |
| EC2 IoT Simulator         |         | EC2 IoT Simulator         |
| MQTT → dev/data           |         | MQTT → prod/data          |
| IoT Core                  |         | IoT Core                  |
| DynamoDB dev-db           |         | DynamoDB prod-db          |
+---------------------------+         +---------------------------+

EC2 Simulator — represents your device simulator publishing MQTT telemetry.
AWS IoT Core — receives MQTT messages from the simulator.

IoT Rules:

Raw-data rule → sends all telemetry to S3 for storage.
Threshold rule → triggers AWS Lambda when data exceeds defined thresholds.
S3 Bucket — collects all raw telemetry (as configured in your Terraform module).
Lambda Alert Handler — invoked by threshold rule; processes the payload, detects anomalies.
Amazon SNS Topic — Lambda publishes alert messages here.
Email Subscription — SNS forwards alerts to your email address (e.g. cet11group1@gmail.com).
IAM Roles & Permissions — implied: IoT → S3, IoT → Lambda, Lambda → SNS.
Terraform State Backend — (S3 + DynamoDB lock) for state management (as present in your repo).
Optional VPC / Networking Context — the simulator runs in EC2 inside your VPC.
Arrows in the diagram show the actual data flow:
Simulator → MQTT → IoT Core
IoT Core → S3 (raw data)
IoT Core → Lambda (on threshold) → SNS → Email

