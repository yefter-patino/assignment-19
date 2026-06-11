#!/usr/bin/env bash
# ===========================================================================
# Assignment 19 - UPDATE (Yefter)
# Re-uploads the templates and UPDATES the existing parent stack.
#
# This is how you "test update by changing instance type":
#   ./scripts/update.sh prod    # dev (t2.micro) -> prod (t3.medium, 2 instances)
#
# Only the EC2 instances change. The VPC, subnets, IGW and security group stay
# exactly as they are - CloudFormation does NOT replace the whole stack.
# ===========================================================================
set -e

ENVIRONMENT="${1:-dev}"
REGION="us-east-1"
ACCOUNT_ID="866934333672"
STACK_NAME="yefter-main-infrastructure-${ENVIRONMENT}"
BUCKET_NAME="yefter-cfn-templates-${ENVIRONMENT}-${ACCOUNT_ID}"
TEMPLATE_DIR="cloudformation"

# Re-upload templates in case anything changed.
echo "Uploading latest templates to S3..."
aws s3 cp "${TEMPLATE_DIR}/network-stack.yaml"  "s3://${BUCKET_NAME}/network-stack.yaml"
aws s3 cp "${TEMPLATE_DIR}/security-stack.yaml" "s3://${BUCKET_NAME}/security-stack.yaml"
aws s3 cp "${TEMPLATE_DIR}/compute-stack.yaml"  "s3://${BUCKET_NAME}/compute-stack.yaml"

TEMPLATE_BASE_URL="https://${BUCKET_NAME}.s3.${REGION}.amazonaws.com"

echo "Updating stack ${STACK_NAME}..."
aws cloudformation update-stack \
  --stack-name "${STACK_NAME}" \
  --template-body "file://${TEMPLATE_DIR}/main-infrastructure.yaml" \
  --parameters \
      ParameterKey=EnvironmentName,ParameterValue="${ENVIRONMENT}" \
      ParameterKey=TemplateBaseUrl,ParameterValue="${TEMPLATE_BASE_URL}" \
  --capabilities CAPABILITY_IAM \
  --rollback-configuration "MonitoringTimeInMinutes=5" \
  --region "${REGION}"

echo "Waiting for the update to finish..."
aws cloudformation wait stack-update-complete \
  --stack-name "${STACK_NAME}" --region "${REGION}"

echo
echo "Stack ${STACK_NAME} updated. Outputs:"
aws cloudformation describe-stacks \
  --stack-name "${STACK_NAME}" --region "${REGION}" \
  --query "Stacks[0].Outputs" --output table
