#!/bin/bash

set -e

REGION="us-east-1"
BUCKET="jibin-terraform-state"
LOCK_TABLE="jibin-iot-terraform-lock"

echo "=============================================="
echo "   JIBIN Terraform Backend Bootstrap"
echo "=============================================="

echo ""
echo "Checking AWS CLI..."
if ! command -v aws &> /dev/null
then
    echo "❌ AWS CLI not installed. Install it first."
    exit 1
fi
echo "✔ AWS CLI found."

echo ""
echo "Checking IAM credentials..."
if ! aws sts get-caller-identity --region $REGION > /dev/null 2>&1
then
    echo "❌ AWS credentials are not configured or invalid."
    exit 1
fi
echo "✔ AWS credentials valid."

echo ""
echo "Checking S3 backend bucket: $BUCKET"
if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
    echo "✔ S3 bucket exists."
else
    echo "⚠ Bucket does not exist. Creating..."
    aws s3api create-bucket \
        --bucket "$BUCKET" \
        --region "$REGION" \
        --create-bucket-configuration LocationConstraint=$REGION
    echo "✔ Bucket created."
fi

echo ""
echo "Checking DynamoDB lock table: $LOCK_TABLE"
if aws dynamodb describe-table --table-name "$LOCK_TABLE" --region "$REGION" > /dev/null 2>&1; then
    echo "✔ DynamoDB lock table exists."
else
    echo "⚠ Lock table does not exist. Creating..."
    aws dynamodb create-table \
        --table-name "$LOCK_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION"
    echo "✔ Lock table created."
fi

echo ""
echo "Running Terraform Bootstrap Apply..."

cd bootstrap

terraform init
terraform apply -auto-approve

echo ""
echo "=============================================="
echo "   Backend Bootstrap Completed Successfully"
echo "   You may now run Terraform in dev/prod."
echo "=============================================="
