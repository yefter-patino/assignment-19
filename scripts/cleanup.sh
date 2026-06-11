#!/usr/bin/env bash
# ===========================================================================
# Assignment 19 - CLEANUP (Yefter)
# Deletes the parent stack (which deletes all nested stacks) and the S3 bucket.
# Run this when you are done so you do not pay for the resources.
#
# Usage:
#   ./scripts/cleanup.sh dev
# ===========================================================================
set -e

ENVIRONMENT="${1:-dev}"
REGION="us-east-1"
ACCOUNT_ID="866934333672"
STACK_NAME="yefter-main-infrastructure-${ENVIRONMENT}"
BUCKET_NAME="yefter-cfn-templates-${ENVIRONMENT}-${ACCOUNT_ID}"

echo "Deleting stack ${STACK_NAME} (this also deletes the nested stacks)..."
aws cloudformation delete-stack --stack-name "${STACK_NAME}" --region "${REGION}"
aws cloudformation wait stack-delete-complete --stack-name "${STACK_NAME}" --region "${REGION}"
echo "Stack deleted."

echo "Emptying and deleting bucket ${BUCKET_NAME}..."
aws s3 rm "s3://${BUCKET_NAME}" --recursive
aws s3 rb "s3://${BUCKET_NAME}"
echo "Bucket deleted."

echo "Cleanup complete."
