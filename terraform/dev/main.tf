terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# DynamoDB table for future Lambda integration
resource "aws_dynamodb_table" "data_table" {
  name         = "${var.prefix}-${var.env}-db"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

module "iot" {
  source = "../modules/iot"
  prefix = var.prefix
  env    = var.env
}
