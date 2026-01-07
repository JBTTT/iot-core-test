#!/bin/bash
set -e

# ================================
# CONFIGURATION — UPDATE IF NEEDED
# ================================
AWS_REGION="us-east-1"
TF_BUCKET="jibin-terraform-state"
TF_TABLE="jibin-iot-terraform-lock"
TF_PREFIX="dev/terraform.tfstate"

ROLE_LIST=(
  "jibin-dev-sim-role"
  "jibin-dev-iot-s3-role"
  "jibin-dev-iot-alert-role"
)

PROFILE_LIST=(
  "jibin-dev-sim-profile"
)

# ================================
# COLORS FOR OUTPUT
# ================================
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

echo ""
echo "${CYAN}============================"
echo "Terraform Backend Cleanup v2"
echo "============================${RESET}"
echo ""

# ================================
# 1. DELETE S3 STATE FILE
# ================================
echo "${CYAN}Step 1: Deleting S3 terraform state file...${RESET}"

aws s3 rm "s3://${TF_BUCKET}/${TF_PREFIX}" --region "$AWS_REGION" || true

echo "${GREEN}✔ S3 state file removed (or did not exist)${RESET}"
echo ""

# ================================
# 2. DELETE DYNAMODB LOCK + DIGEST RECORDS
# ================================
echo "${CYAN}Step 2: Cleaning DynamoDB lock table...${RESET}"

aws dynamodb delete-item \
  --table-name "$TF_TABLE" \
  --key "{\"LockID\": {\"S\": \"${TF_PREFIX}-md5\"}}" \
  --region "$AWS_REGION" || true

aws dynamodb delete-item \
  --table-name "$TF_TABLE" \
  --key "{\"LockID\": {\"S\": \"${TF_PREFIX}-lock\"}}" \
  --region "$AWS_REGION" || true

echo "${GREEN}✔ DynamoDB checksum + lock removed (or didn't exist)${RESET}"
echo ""

# ================================
# 3. DELETE IAM INSTANCE PROFILES
# ================================
echo "${CYAN}Step 3: Cleaning IAM Instance Profiles...${RESET}"

for profile in "${PROFILE_LIST[@]}"; do
  echo "Checking instance profile: $profile"

  # Remove roles from instance profile safely
  roles=$(aws iam get-instance-profile --instance-profile-name "$profile" \
            --query "InstanceProfile.Roles[*].RoleName" \
            --output text 2>/dev/null || true)

  if [[ ! -z "$roles" ]]; then
    for r in $roles; do
      echo " - Detaching role $r from profile $profile"
      aws iam remove-role-from-instance-profile \
        --instance-profile-name "$profile" \
        --role-name "$r" || true
    done
  fi

  echo " - Deleting instance profile $profile"
  aws iam delete-instance-profile \
    --instance-profile-name "$profile" || true
done

echo "${GREEN}✔ IAM instance profiles cleaned${RESET}"
echo ""

# ================================
# 4. DELETE IAM ROLES
# ================================
echo "${CYAN}Step 4: Cleaning IAM roles...${RESET}"

for role in "${ROLE_LIST[@]}"; do
  echo "Processing role: $role"

  # Detach all policies
  policies=$(aws iam list-attached-role-policies \
                --role-name "$role" \
                --query "AttachedPolicies[*].PolicyArn" \
                --output text 2>/dev/null || true)

  for p in $policies; do
    echo " - Detaching policy: $p"
    aws iam detach-role-policy --role-name "$role" --policy-arn "$p" || true
  done

  # Inline policies
  inline=$(aws iam list-role-policies \
              --role-name "$role" \
              --query "PolicyNames[*]" \
              --output text 2>/dev/null || true)

  for ip in $inline; do
    echo " - Deleting inline policy: $ip"
    aws iam delete-role-policy --role-name "$role" --policy-name "$ip" || true
  done

  # Delete the role
  echo " - Deleting role: $role"
  aws iam delete-role --role-name "$role" || true
done

echo "${GREEN}✔ IAM roles cleaned${RESET}"
echo ""

# ================================
# 5. FINAL CHECK
# ================================
echo "${CYAN}Step 5: Verifying DynamoDB table is empty...${RESET}"

aws dynamodb scan --table-name "$TF_TABLE" --region "$AWS_REGION"

echo ""
echo "${GREEN}=============================================="
echo "Terraform backend cleanup completed SUCCESSFULLY"
echo "You can now run:"
echo "   terraform -chdir=terraform/dev init"
echo "==============================================${RESET}"
echo ""
