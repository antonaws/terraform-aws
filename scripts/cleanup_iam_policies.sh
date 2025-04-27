#!/bin/bash

USER="container"
POLICIES=("s3_full_access_policy" "s3_bucket_management_policy" "fsx_s3_access_policy" "terraform_admin_permissions_policy")

# Detach policies
for POLICY in "${POLICIES[@]}"; do
  POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY'].Arn" --output text)
  if [ -n "$POLICY_ARN" ]; then
    aws iam detach-user-policy --user-name "$USER" --policy-arn "$POLICY_ARN"
    echo "Detached policy $POLICY_ARN from $USER"
  else
    echo "Policy $POLICY not found, skipping detach"
  fi
done

# Delete policies
for POLICY in "${POLICIES[@]}"; do
  POLICY_ARN=$(aws iam list-policies --query "Policies[?PolicyName=='$POLICY'].Arn" --output text)
  if [ -n "$POLICY_ARN" ]; then
    aws iam delete-policy --policy-arn "$POLICY_ARN"
    echo "Deleted policy $POLICY_ARN"
  else
    echo "Policy $POLICY not found, skipping deletion"
  fi
done
