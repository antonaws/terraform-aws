
```markdown
# Universal EKS Terraform Base

A production-ready Terraform configuration for AWS EKS with static node groups, proper networking, and essential add-ons.

## Features

- **VPC Configuration**:
  - Public and private subnets across multiple AZs
  - NAT gateways for private subnet internet access
  - Proper security groups and network ACLs

- **EKS Cluster**:
  - Static node groups (no auto-scaling to prevent unexpected behavior)
  - Separate node groups for different workload types (core, compute, GPU)
  - Proper IAM role configuration

- **Add-ons**:
  - AWS Load Balancer Controller (for ALB/NLB integration)
  - Metrics Server (for basic monitoring)
  - AWS FSx CSI Driver (for storage)
  - NVIDIA GPU support (for ML/AI workloads)

## Prerequisites

- AWS CLI configured with appropriate access
- Terraform v1.0.0+ installed
- kubectl installed
- Access to create VPC, EKS, IAM, and related resources in AWS

## Usage

1. Clone this repository
   ```bash
   git clone https://github.com/yourusername/universal-eks-terraform-base.git
   cd universal-eks-terraform-base
   ```

2. Initialize Terraform
   ```bash
   terraform init
   ```

3. Customize your deployment by creating a `terraform.tfvars` file
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your desired settings
   ```

4. Deploy the infrastructure
   ```bash
   terraform apply
   ```

5. Configure kubectl to connect to your new cluster
   ```bash
   aws eks update-kubeconfig --name <cluster-name> --region <region>
   ```

## Extending with Helm Charts

This base configuration provides the infrastructure layer. To deploy applications on top:

1. Get the cluster name and endpoint from Terraform outputs:
   ```bash
   terraform output cluster_name
   terraform output cluster_endpoint
   ```

2. Use Helm to deploy additional components:
   ```bash
   # Add a Helm repository
   helm repo add bitnami https://charts.bitnami.com/bitnami

   # Install a chart
   helm install my-release bitnami/nginx
   ```

## Customization

Modify `variables.tf` or create a custom `terraform.tfvars` file to adjust:

- Region and availability zones
- VPC CIDR ranges
- Node group sizes and instance types
- Cluster version
- Additional add-ons
