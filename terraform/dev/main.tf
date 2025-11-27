provider "aws" {
  region = var.region
}

#############################################
# VPC (dedicated for dev)
#############################################

module "vpc" {
  source = "../modules/vpc"
  prefix = var.prefix
  env    = var.env
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
# IoT Core (dev)
#############################################

module "iot" {
  source   = "../modules/iot"
  prefix   = var.prefix
  env      = var.env
  s3_bucket = aws_s3_bucket.iot_raw_data.bucket
}

#############################################
# IoT Endpoint (dev)
#############################################

data "aws_iot_endpoint" "core" {
  endpoint_type = "iot:Data-ATS"
}

#############################################
# EC2 Simulator (dev)
#############################################

module "ec2_simulator" {
  source       = "../modules/ec2_simulator"
  prefix       = var.prefix
  env          = var.env
  subnet_id    = module.vpc.public_subnet_id
  sg_id        = module.vpc.sg_id
  ami_id       = "ami-0c101f26f147fa7fd" # Amazon Linux 2 (us-east-1)
  iot_endpoint = data.aws_iot_endpoint.core.endpoint_address
}

resource "aws_s3_bucket" "iot_raw_data" {
  bucket = "${var.prefix}-${var.env}-iot-data"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.iot_raw_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

