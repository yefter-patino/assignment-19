#!/usr/bin/env bash
# ===========================================================================
# Assignment 19 - VALIDATE (Yefter)
# Checks all four templates with the AWS CLI before you deploy.
#
# Usage:
#   ./scripts/validate.sh
# ===========================================================================
set -e

REGION="us-east-1"
TEMPLATE_DIR="cloudformation"

for FILE in main-infrastructure network-stack security-stack compute-stack; do
  echo "Validating ${FILE}.yaml ..."
  aws cloudformation validate-template \
    --template-body "file://${TEMPLATE_DIR}/${FILE}.yaml" \
    --region "${REGION}" > /dev/null
  echo "  OK"
done

echo "All templates are valid."
