#!/bin/bash

POLICY_ARNS=(
  "arn:aws:iam::058264135704:policy/slinky-s3-access-policy"
  "arn:aws:iam::058264135704:policy/slinky-s3-policy"
)

for POLICY_ARN in "${POLICY_ARNS[@]}"; do
  echo "Processing policy $POLICY_ARN"
  
  VERSIONS=$(aws iam list-policy-versions --policy-arn $POLICY_ARN --query 'Versions[?IsDefaultVersion==`false`].VersionId' --output text)
  
  for VERSION_ID in $VERSIONS; do
    echo "Deleting version $VERSION_ID of $POLICY_ARN"
    aws iam delete-policy-version --policy-arn $POLICY_ARN --version-id $VERSION_ID
  done
  
  echo "Deleting policy $POLICY_ARN"
  aws iam delete-policy --policy-arn $POLICY_ARN
  
done
