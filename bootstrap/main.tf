###############################################
# BOOTSTRAP MODULE
# Creates S3 bucket + DynamoDB lock table
# for Terraform remote backend
###############################################

provider "aws" {
  region = var.region
}

###############################################
# S3 STATE BUCKET
###############################################

resource "aws_s3_bucket" "tf_state" {
  bucket = var.state_bucket_name

  tags = {
    Name        = var.state_bucket_name
    Project     = var.prefix
    Environment = "bootstrap"
  }
}

resource "aws_s3_bucket_public_access_block" "state_bucket" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

###############################################
# DynamoDB Lock Table
###############################################

resource "aws_dynamodb_table" "tf_lock" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = var.lock_table_name
    Project     = var.prefix
    Environment = "bootstrap"
  }
}
