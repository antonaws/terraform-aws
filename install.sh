#!/bin/bash

# List of Terraform modules to apply in sequence
targets=(
  "module.vpc"
  "module.eks"
)

# Initialize Terraform
echo "Initializing ..."
terraform init --upgrade || echo "\"terraform init\" failed"

# Initialize Terraform
echo "Initializing ..."
terraform init --upgrade || { echo "\"terraform init\" failed"; exit 1; }

# Apply IAM policies first to resolve permission errors
echo "Applying IAM policies..."
terraform apply -target=aws_iam_policy -auto-approve || { echo "FAILED: IAM policies apply failed"; exit 1; }



echo "SUCCESS: IAM policies applied successfully"


# Apply modules in sequence
for target in "${targets[@]}"
do
  echo "Applying module $target..."
  apply_output=$(terraform apply -target="$target" -auto-approve 2>&1 | tee /dev/tty)
  if [[ ${PIPESTATUS[0]} -eq 0 && $apply_output == *"Apply complete"* ]]; then
    echo "SUCCESS: Terraform apply of $target completed successfully"
  else
    echo "FAILED: Terraform apply of $target failed"
    exit 1
  fi
done

# Final apply to catch any remaining resources
echo "Applying remaining resources..."
apply_output=$(terraform apply -auto-approve 2>&1 | tee /dev/tty)
if [[ ${PIPESTATUS[0]} -eq 0 && $apply_output == *"Apply complete"* ]]; then
  echo "SUCCESS: Terraform apply of all modules completed successfully"
else
  echo "FAILED: Terraform apply of all modules failed"
  exit 1
fi
