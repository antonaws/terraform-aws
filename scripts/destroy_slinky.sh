#!/bin/bash
set -euo pipefail

echo "Initializing Terraform..."
terraform init --upgrade

echo "Destroying Slurm resources..."
terraform destroy -target="helm_release.slurm" -auto-approve || true
helm uninstall slurm -n slurm || true
kubectl delete pvc data-slurm-mariadb-0 -n slurm || true

echo "Destroying Slurm operator..."
terraform destroy -target="helm_release.slurm_operator" -auto-approve || true
helm uninstall slurm-operator -n slinky || true

echo "Destroying IAM policies..."
terraform destroy -target="aws_iam_user_policy_attachment.attach_terraform_rds_s3" -auto-approve
terraform destroy -target="aws_iam_user_policy_attachment.attach_rds_full_access" -auto-approve
terraform destroy -target="aws_iam_user_policy_attachment.attach_terraform_permissions" -auto-approve
terraform destroy -target="aws_iam_user_policy_attachment.attach_s3_bucket_management" -auto-approve
terraform destroy -target="aws_iam_user_policy_attachment.attach_s3_full" -auto-approve
terraform destroy -target="aws_iam_policy.terraform_rds_s3_policy" -auto-approve
terraform destroy -target="aws_iam_policy.rds_full_access" -auto-approve
terraform destroy -target="aws_iam_policy.terraform_permissions" -auto-approve
terraform destroy -target="aws_iam_policy.s3_bucket_management" -auto-approve
terraform destroy -target="aws_iam_policy.s3_full_access" -auto-approve

echo "Destroying EKS cluster..."
terraform destroy -target="module.eks" -auto-approve

echo "Destroying VPC..."
terraform destroy -target="module.vpc" -auto-approve

echo "Final cleanup of any remaining resources..."
terraform destroy -auto-approve

echo "Environment destroyed successfully!"
