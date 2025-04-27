#!/bin/bash
set -euo pipefail

echo "Initializing Terraform..."
terraform init --upgrade

echo "Applying VPC and EKS modules..."
terraform apply -target="module.vpc" -auto-approve
terraform apply -target="module.eks" -auto-approve

echo "Applying IAM policies..."
terraform apply -target="aws_iam_policy.s3_full_access" -auto-approve
terraform apply -target="aws_iam_policy.s3_bucket_management" -auto-approve
terraform apply -target="aws_iam_policy.terraform_permissions" -auto-approve
terraform apply -target="aws_iam_policy.rds_full_access" -auto-approve
terraform apply -target="aws_iam_policy.terraform_rds_s3_policy" -auto-approve
terraform apply -target="aws_iam_user_policy_attachment.attach_s3_full" -auto-approve
terraform apply -target="aws_iam_user_policy_attachment.attach_s3_bucket_management" -auto-approve
terraform apply -target="aws_iam_user_policy_attachment.attach_terraform_permissions" -auto-approve
terraform apply -target="aws_iam_user_policy_attachment.attach_rds_full_access" -auto-approve
terraform apply -target="aws_iam_user_policy_attachment.attach_terraform_rds_s3" -auto-approve

echo "Deploying Slurm operator..."
terraform apply -target="helm_release.slurm_operator" -auto-approve

echo "Deploying
