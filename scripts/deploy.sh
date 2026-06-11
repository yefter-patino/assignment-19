#!/usr/bin/env bash
# ===========================================================================
# Assignment 19 - DEPLOY (Yefter)
# Uploads the 3 nested templates to S3, then CREATES the parent stack.
#
# Usage:
#   ./scripts/deploy.sh dev     # default
#   ./scripts/deploy.sh prod
# ===========================================================================
set -e  # stop the script if any command fails

# ---- Variables (no hardcoding inside the templates - it all lives here) ----
ENVIRONMENT="${1:-dev}"                 # 1st argument: dev or prod (default dev)
REGION="us-east-1"
ACCOUNT_ID="866934333672"
STACK_NAME="yefter-main-infrastructure-${ENVIRONMENT}"
BUCKET_NAME="yefter-cfn-templates-${ENVIRONMENT}-${ACCOUNT_ID}"
TEMPLATE_DIR="cloudformation"

echo "Environment : ${ENVIRONMENT}"
echo "Region      : ${REGION}"
echo "Stack name  : ${STACK_NAME}"
echo "S3 bucket   : ${BUCKET_NAME}"
echo

# ---- 1. Make an S3 bucket to hold the nested templates (if not there yet) ----
# Nested stacks must be referenced from S3, so the child templates live there.
if ! aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "Creating bucket ${BUCKET_NAME}..."
  aws s3 mb "s3://${BUCKET_NAME}" --region "${REGION}"
fi

# ---- 2. Upload the three nested templates ----
echo "Uploading nested templates to S3..."
aws s3 cp "${TEMPLATE_DIR}/network-stack.yaml"  "s3://${BUCKET_NAME}/network-stack.yaml"
aws s3 cp "${TEMPLATE_DIR}/security-stack.yaml" "s3://${BUCKET_NAME}/security-stack.yaml"
aws s3 cp "${TEMPLATE_DIR}/compute-stack.yaml"  "s3://${BUCKET_NAME}/compute-stack.yaml"

TEMPLATE_BASE_URL="https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com"

# ---- 3. Create the parent stack ----
# --on-failure ROLLBACK              -> if creation fails, undo everything.
# --rollback-configuration ...       -> watch the stack for 5 minutes after the
#                                       update and roll back if an alarm fires.
echo "Creating parent stack ${STACK_NAME}..."
aws cloudformation create-stack \
  --stack-name "${STACK_NAME}" \
  --template-body "file://${TEMPLATE_DIR}/main-infrastructure.yaml" \
  --parameters \
      ParameterKey=EnvironmentName,ParameterValue="${ENVIRONMENT}" \
      ParameterKey=TemplateBaseUrl,ParameterValue="${TEMPLATE_BASE_URL}" \
  --capabilities CAPABILITY_IAM \
  --on-failure ROLLBACK \
  --rollback-configuration "MonitoringTimeInMinutes=5" \
  --region "${REGION}"

echo "Waiting for the stack to finish creating (this can take a few minutes)..."
aws cloudformation wait stack-create-complete \
  --stack-name "${STACK_NAME}" --region "${REGION}"

echo
echo "Stack ${STACK_NAME} created. Outputs:"
aws cloudformation describe-stacks \
  --stack-name "${STACK_NAME}" --region "${REGION}" \
  --query "Stacks[0].Outputs" --output table
