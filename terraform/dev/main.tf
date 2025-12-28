provider "aws" {
  region = var.region
}

############################################
# Get AWS Account ID
############################################
data "aws_caller_identity" "current" {}

#############################################
# VPC (dedicated for dev)
#############################################
module "vpc" {
  source = "../modules/vpc"
  prefix = var.prefix
  env    = var.env
  region = var.region
}

#############################################
# DynamoDB Table (dev)
#############################################
resource "aws_dynamodb_table" "db" {
  name         = "${var.prefix}-${var.env}-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Name = "${var.prefix}-${var.env}-db"
  }
}

#############################################
# S3 Bucket for RAW IoT Telemetry
#############################################
resource "aws_s3_bucket" "iot_raw_data" {
  bucket        = "${var.prefix}-${var.env}-iot-data-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.iot_raw_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

#############################################
# IoT Core
#############################################
module "iot" {
  source    = "../modules/iot"
  prefix    = var.prefix
  env       = var.env
  s3_bucket = aws_s3_bucket.iot_raw_data.bucket
}

data "aws_iot_endpoint" "core" {
  endpoint_type = "iot:Data-ATS"
}

#############################################
# EC2 Simulator
#############################################
module "ec2_simulator" {
  source       = "../modules/ec2_simulator"
  prefix       = var.prefix
  env          = var.env
  subnet_id    = module.vpc.public_subnets[0]
  sg_id        = module.vpc.security_group_id
  ami_id       = "ami-0c101f26f147fa7fd"
  iot_endpoint = data.aws_iot_endpoint.core.endpoint_address
}

#############################################
# Threshold Alerts
#############################################
module "iot_sns_lambda_alerts" {
  source = "../modules/iot_sns_lambda_alerts"

  prefix     = var.prefix
  env        = var.env
  aws_region = var.region
  iot_topic  = "${var.prefix}/${var.env}/data"

  alert_email = "perseverancejb@hotmail.com"
}

#############################################
# ECR
#############################################
module "iot_simulator_ecr" {
  source = "../modules/ecr"
  prefix = var.prefix
  env    = var.env
  repository_name = "iot-simulator"
}

#############################################
# ECS Cluster
#############################################
module "ecs" {
  source = "../modules/ecs_cluster"
  prefix = var.prefix
  env    = var.env
}

#############################################
# ECS Simulator Service
#############################################
module "iot_simulator_ecs" {
  source = "../modules/iot_simulator_ecs"

  prefix = var.prefix
  env    = var.env
  region = var.region

  cluster_id         = module.ecs.cluster_id
  subnet_ids         = module.vpc.public_subnets
  security_group_ids = [module.vpc.security_group_id]

  ecr_repository_url = module.iot_simulator_ecr.repository_url
  image_tag          = "latest"
}

#############################################
# Monitoring Stack
#############################################
module "monitoring" {
  source = "../modules/monitoring_ecs"

  prefix = var.prefix
  env    = var.env
  region = var.region

  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnets
  private_subnet_ids = module.vpc.private_subnets

  allowed_cidrs = ["YOUR_IP/32"]
}