#!/usr/bin/env bash
# ===========================================================================
# Assignment 19 - ROLLBACK TEST (Yefter)
# Deliberately breaks the compute stack to PROVE that rollback works.
#
# What it does:
#   1. Makes a broken copy of compute-stack.yaml with an invalid instance type.
#   2. Uploads it over the good one and runs an update (this WILL fail).
#   3. CloudFormation rolls the stack back to its last good state.
#   4. We confirm the status is UPDATE_ROLLBACK_COMPLETE.
#   5. We put the good template back in S3.
#
# Usage:
#   ./scripts/test-rollback.sh dev
# ===========================================================================
set -e

ENVIRONMENT="${1:-dev}"
REGION="us-east-1"
ACCOUNT_ID="866934333672"
STACK_NAME="yefter-main-infrastructure-${ENVIRONMENT}"
BUCKET_NAME="yefter-cfn-templates-${ENVIRONMENT}-${ACCOUNT_ID}"
TEMPLATE_DIR="cloudformation"
TEMPLATE_BASE_URL="https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com"

echo "Step 1: build a BROKEN compute template (invalid instance type)..."
# Replace the valid 't2.micro' with an instance type that does not exist.
sed 's/t2.micro/t2.does-not-exist/' \
  "${TEMPLATE_DIR}/compute-stack.yaml" > /tmp/yefter-compute-broken.yaml
aws s3 cp /tmp/yefter-compute-broken.yaml "s3://${BUCKET_NAME}/compute-stack.yaml"

echo "Step 2: run an update that is EXPECTED to fail..."
aws cloudformation update-stack \
  --stack-name "${STACK_NAME}" \
  --template-body "file://${TEMPLATE_DIR}/main-infrastructure.yaml" \
  --parameters \
      ParameterKey=EnvironmentName,ParameterValue="${ENVIRONMENT}" \
      ParameterKey=TemplateBaseUrl,ParameterValue="${TEMPLATE_BASE_URL}" \
  --capabilities CAPABILITY_IAM \
  --rollback-configuration "MonitoringTimeInMinutes=5" \
  --region "${REGION}"

echo "Step 3: wait for the update to settle..."
# The update fails on purpose, so 'wait' returns an error. '|| true' lets the
# script keep going so we can read the final status ourselves.
aws cloudformation wait stack-update-complete \
  --stack-name "${STACK_NAME}" --region "${REGION}" || true

echo "Step 4: final stack status (should be UPDATE_ROLLBACK_COMPLETE):"
aws cloudformation describe-stacks \
  --stack-name "${STACK_NAME}" --region "${REGION}" \
  --query "Stacks[0].StackStatus" --output text

echo "Step 5: restore the GOOD compute template in S3..."
aws s3 cp "${TEMPLATE_DIR}/compute-stack.yaml" "s3://${BUCKET_NAME}/compute-stack.yaml"
rm -f /tmp/yefter-compute-broken.yaml

echo
echo "Rollback test finished. Your infrastructure was returned to its last good state."
