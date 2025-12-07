#!/bin/bash
set -e

##############################################
# CONFIGURATION
##############################################

PREFIX="cet11-grp1"
ENV="dev"

AWS_REGION="us-east-1"

IOT_POLICY="${PREFIX}-${ENV}_iot_policy"
IOT_THING="${PREFIX}-${ENV}-device"
S3_BUCKET="${PREFIX}-${ENV}-iot-data"
DDB_TABLE="${PREFIX}-${ENV}-db"

SIM_ROLE="${PREFIX}-${ENV}-sim-role"
IOT_S3_ROLE="${PREFIX}-${ENV}-iot-s3-role"
LAMBDA_ROLE="${PREFIX}-${ENV}-iot-alert-role"

SSM_CERT="/iot/${PREFIX}/${ENV}/cert"
SSM_KEY="/iot/${PREFIX}/${ENV}/key"

LAMBDA_FUNC="${PREFIX}-${ENV}-iot-alert-handler"
SNS_TOPIC="${PREFIX}-${ENV}-alerts"

STATE_BUCKET="${PREFIX}-terraform-state"
STATE_KEY="${ENV}/terraform.tfstate"

LOCK_TABLE="${PREFIX}-iot-terraform-lock"

##############################################
echo "==== 1. Cleanup IoT Core Resources ===="
##############################################

echo "Finding certificate..."
CERT_ARN=$(aws iot list-things | jq -r ".things[] | select(.thingName==\"$IOT_THING\")" | jq -r .thingName)

CERT_ID=$(aws iot list-certificates --query "certificates[0].certificateId" --output text)

if [[ "$CERT_ID" != "None" ]]; then
    echo "Deactivating cert $CERT_ID..."
    aws iot update-certificate --certificate-id "$CERT_ID" --new-status INACTIVE || true

    echo "Detaching IoT policy..."
    aws iot detach-policy --policy-name "$IOT_POLICY" \
        --target arn:aws:iot:$AWS_REGION:$(aws sts get-caller-identity --query Account --output text):cert/$CERT_ID || true

    echo "Deleting certificate..."
    aws iot delete-certificate --certificate-id "$CERT_ID" --force-delete || true
else
    echo "No IoT certificate found."
fi

echo "Deleting IoT Thing..."
aws iot delete-thing --thing-name "$IOT_THING" || true

echo "Deleting IoT Policy..."
aws iot delete-policy --policy-name "$IOT_POLICY" || true


##############################################
echo "==== 2. Cleanup S3 Bucket ===="
##############################################

echo "Emptying S3 bucket $S3_BUCKET..."
aws s3 rm s3://$S3_BUCKET --recursive || true

echo "Deleting S3 bucket..."
aws s3api delete-bucket --bucket $S3_BUCKET --region $AWS_REGION || true


##############################################
echo "==== 3. Cleanup DynamoDB Tables ===="
##############################################

echo "Deleting app DynamoDB table $DDB_TABLE..."
aws dynamodb delete-table --table-name $DDB_TABLE --region $AWS_REGION || true

echo "Removing lock table digest & lock..."
aws dynamodb delete-item --table-name $LOCK_TABLE \
  --key "{\"LockID\": {\"S\": \"$ENV/terraform.tfstate-md5\"}}" || true

aws dynamodb delete-item --table-name $LOCK_TABLE \
  --key "{\"LockID\": {\"S\": \"$ENV/terraform.tfstate-lock\"}}" || true


##############################################
echo "==== 4. Cleanup IAM Roles & Instance Profiles ===="
##############################################

delete_role () {
  ROLE=$1
  echo "Processing IAM Role: $ROLE"

  INST_PROFILE=$(aws iam list-instance-profiles --query "InstanceProfiles[?contains(Roles[].RoleName, '$ROLE')].InstanceProfileName" --output text)

  if [[ ! -z "$INST_PROFILE" ]]; then
    echo "Removing role from instance profile $INST_PROFILE..."
    aws iam remove-role-from-instance-profile \
      --instance-profile-name "$INST_PROFILE" \
      --role-name "$ROLE" || true

    echo "Deleting instance profile $INST_PROFILE..."
    aws iam delete-instance-profile --instance-profile-name "$INST_PROFILE" || true
  fi

  echo "Detaching managed policies..."
  for POLICY_ARN in $(aws iam list-attached-role-policies --role-name "$ROLE" --query "AttachedPolicies[*].PolicyArn" --output text); do
    aws iam detach-role-policy --role-name "$ROLE" --policy-arn "$POLICY_ARN" || true
  done

  echo "Deleting inline policies..."
  for POLICY_NAME in $(aws iam list-role-policies --role-name "$ROLE" --query "PolicyNames[]" --output text); do
    aws iam delete-role-policy --role-name "$ROLE" --policy-name "$POLICY_NAME" || true
  done

  echo "Deleting IAM Role $ROLE..."
  aws iam delete-role --role-name "$ROLE" || true
}

delete_role $SIM_ROLE
delete_role $IOT_S3_ROLE
delete_role $LAMBDA_ROLE


##############################################
echo "==== 5. Cleanup SSM Parameters ===="
##############################################

aws ssm delete-parameter --name "$SSM_CERT" || true
aws ssm delete-parameter --name "$SSM_KEY" || true


##############################################
echo "==== 6. Cleanup Lambda Function ===="
##############################################

aws lambda delete-function --function-name $LAMBDA_FUNC || true


##############################################
echo "==== 7. Cleanup SNS Topic ===="
##############################################

TOPIC_ARN=$(aws sns list-topics --query "Topics[?contains(TopicArn, '$SNS_TOPIC')].TopicArn" --output text)

if [[ ! -z "$TOPIC_ARN" ]]; then
  echo "Deleting SNS topic: $TOPIC_ARN"
  aws sns delete-topic --topic-arn "$TOPIC_ARN" || true
fi


##############################################
echo "==== 8. Cleanup Terraform State Files ===="
##############################################

echo "Deleting remote Terraform state file..."
aws s3 rm s3://$STATE_BUCKET/$STATE_KEY || true

echo "Cleanup completed successfully!"
