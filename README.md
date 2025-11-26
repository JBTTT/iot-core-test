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
