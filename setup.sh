#!/bin/bash

echo "=== AWS EKS Tools Installation and Configuration Script ==="
echo "-------------------------------------------------------"

# Function to check if a command was successful
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ Success: $1"
    else
        echo "❌ Error: $1 failed"
        exit 1
    fi
}

# Update system packages
echo "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y
check_success "System update"

# Install AWS CLI
echo -e "\nInstalling AWS CLI..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    check_success "AWS CLI installation"
else
    echo "AWS CLI is already installed"
fi

# Install kubectl
echo -e "\nInstalling kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    check_success "kubectl installation"
else
    echo "kubectl is already installed"
fi

# Install aws-iam-authenticator
echo -e "\nInstalling aws-iam-authenticator..."
if ! command -v aws-iam-authenticator &> /dev/null; then
    curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.9/aws-iam-authenticator_0.5.9_linux_amd64
    chmod +x ./aws-iam-authenticator
    sudo mv aws-iam-authenticator /usr/local/bin/
    check_success "aws-iam-authenticator installation"
else
    echo "aws-iam-authenticator is already installed"
fi

# Configure AWS CLI
echo -e "\nConfiguring AWS CLI..."
echo "Please enter your AWS credentials:"
aws configure

# Update kubeconfig for EKS cluster
echo -e "\nUpdating kubeconfig for EKS cluster..."
aws eks update-kubeconfig --name sagemaker-hyperpod-eks-cluster --region us-east-2
check_success "kubeconfig update"

# Verify connections
echo -e "\nVerifying connections..."
echo "Testing AWS CLI:"
aws sts get-caller-identity
check_success "AWS CLI verification"

echo -e "\nTesting kubectl:"
kubectl get nodes
check_success "kubectl verification"

echo -e "\n=== Installation and Configuration Complete ==="
echo "You can now use kubectl to interact with your EKS cluster"