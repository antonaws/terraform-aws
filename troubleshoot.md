# Troubleshooting Your EKS Cluster

This section covers common issues you might encounter when working with EKS clusters and how to resolve them.

## Authentication Issues

### Unable to connect to the Kubernetes API server

**Error Message:** 
```
The server has asked for the client to provide credentials
```

**Troubleshooting Steps:**
1. Verify AWS credentials and region:
   ```bash
   aws sts get-caller-identity
   aws configure get region
   ```

2. Ensure kubeconfig is correctly updated:
   ```bash
   aws eks update-kubeconfig --name your-cluster-name --region your-region
   ```

3. Check for aws-iam-authenticator:
   ```bash
   which aws-iam-authenticator
   # Install if missing
   curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator
   chmod +x ./aws-iam-authenticator
   sudo mv aws-iam-authenticator /usr/local/bin/
   ```

4. Verify IAM user/role has cluster access:
   ```bash
   # Check aws-auth ConfigMap
   kubectl describe configmap -n kube-system aws-auth
   ```

### Invalid Signature Errors

**Error Message:**
```
InvalidSignatureException: The request signature we calculated does not match the signature you provided
```

**Troubleshooting Steps:**
1. Check system time synchronization:
   ```bash
   sudo apt-get install -y ntp
   sudo service ntp restart
   ```

2. Verify correct AWS credentials are being used:
   ```bash
   aws configure list
   ```

3. Try setting credentials explicitly:
   ```bash
   export AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
   export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXX
   ```

## Resource Conflicts in Terraform

### Resources Already Exist

**Error Message:**
```
Error: creating IAM Role: EntityAlreadyExists: Role with name role-name already exists
```

**Solutions:**
1. Change resource names in your Terraform files:
   ```hcl
   resource "aws_iam_role" "example" {
     name = "example-role-new"  # Append suffix to make unique
   }
   ```

2. Import existing resources:
   ```bash
   terraform import aws_iam_role.example role-name
   ```

3. Delete existing resources (if appropriate):
   ```bash
   aws iam delete-role --role-name role-name
   ```

4. Use random suffixes for resources:
   ```hcl
   resource "random_id" "suffix" {
     byte_length = 4
   }
   
   resource "aws_iam_role" "example" {
     name = "example-role-${random_id.suffix.hex}"
   }
   ```

## Terraform Deployment Errors

### Add-on Dependencies and Timing Issues

**Error Message:**
```
Error: waiting for EKS Add-On create: unexpected state 'CREATE_FAILED', last error: failed calling webhook
```

**Solutions:**
1. Apply resources in sequence:
   ```bash
   terraform apply -target=module.vpc -target=module.eks
   # Wait a few minutes
   terraform apply -target=module.eks_blueprints_addons.aws_eks_addon.this["aws-load-balancer-controller"]
   # Wait a few minutes
   terraform apply
   ```

2. Add explicit dependencies and delays:
   ```hcl
   resource "time_sleep" "wait_for_load_balancer" {
     depends_on = [module.eks_blueprints_addons.aws_eks_addon.this["aws-load-balancer-controller"]]
     create_duration = "90s"
   }
   
   resource "aws_eks_addon" "cloudwatch" {
     depends_on = [time_sleep.wait_for_load_balancer]
     # Rest of resource definition...
   }
   ```

### Deprecated Arguments Warning

**Warning Message:**
```
Warning: Argument is deprecated - inline_policy is deprecated
```

**Solution:**
Update to newer syntax:
```hcl
resource "aws_iam_role_policy" "example_policy" {
  name   = "example-policy"
  role   = aws_iam_role.example.id
  policy = jsonencode({
    # Policy document
  })
}
```

## Network and Connectivity Issues

### DNS Resolution Problems

**Error Messages:**
```
dial tcp: lookup kubernetes.default.svc on 127.0.0.53:53: server misbehaving
```

**Troubleshooting Steps:**
1. Check CoreDNS pods:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=kube-dns
   ```

2. Verify network policies:
   ```bash
   kubectl get networkpolicy --all-namespaces
   ```

3. Check VPC DNS settings:
   ```bash
   aws ec2 describe-vpcs --vpc-id your-vpc-id --query 'Vpcs[0].EnableDnsHostnames'
   ```

### Load Balancer Service Issues

**Symptom:** Services with type LoadBalancer stay in 'Pending' state

**Troubleshooting Steps:**
1. Check AWS Load Balancer Controller:
   ```bash
   kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
   kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
   ```

2. Verify subnet tags:
   ```bash
   aws ec2 describe-subnets --filters "Name=vpc-id,Values=your-vpc-id" --query 'Subnets[*].[SubnetId,Tags]'
   ```
   Public subnets should have tag `kubernetes.io/role/elb=1`
   Private subnets should have tag `kubernetes.io/role/internal-elb=1`

## Node Health Issues

### Nodes Not Ready

**Symptom:** Nodes show 'NotReady' status

**Troubleshooting Steps:**
1. Check node conditions:
   ```bash
   kubectl describe nodes | grep -i condition -A5
   ```

2. Check kubelet logs:
   ```bash
   # Connect to the node via SSM Session Manager
   aws ssm start-session --target your-instance-id
   
   # Check logs on the node
   sudo journalctl -u kubelet -n 100
   ```

3. Verify node resources:
   ```bash
   kubectl describe nodes | grep -i capacity -A5
   ```

### GPU Node Issues

**Symptom:** GPU workloads fail or GPU not detected

**Troubleshooting Steps:**
1. Check NVIDIA device plugin:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=nvidia-gpu-device-plugin
   ```

2. Verify GPU node labels:
   ```bash
   kubectl get nodes -L nvidia.com/gpu
   ```

3. Check NVIDIA drivers on nodes:
   ```bash
   # Connect to the GPU node via SSM
   aws ssm start-session --target your-instance-id
   
   # Check driver installation
   nvidia-smi
   ```

## General EKS Diagnostics

### Collecting logs for AWS support

```bash
# Install EKS support tools
curl -LO https://github.com/aws/eks-distro-build-tooling/releases/download/eks-distro-support-tool/eks-distro-support-tool_linux_amd64
chmod +x ./eks-distro-support-tool_linux_amd64
sudo mv eks-distro-support-tool_linux_amd64 /usr/local/bin/eks-distro-support-tool

# Run the diagnostics tool
eks-distro-support-tool --collect-eks-cluster
```

### Check EKS Control Plane Logs

If you have CloudWatch logs enabled for your EKS cluster:

```bash
# List log groups
aws logs describe-log-groups --query 'logGroups[?contains(logGroupName, `your-cluster-name`)].logGroupName'

# Get logs
aws logs get-log-events --log-group-name /aws/eks/your-cluster-name/cluster --log-stream-name kube-apiserver-audit
```

### Creating Admin Access for Debugging

If you need emergency cluster access:

```bash
# Create admin YAML
cat <<EOF > eks-admin.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eks-admin
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: eks-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: eks-admin
  namespace: kube-system
EOF

# Apply and get token
kubectl apply -f eks-admin.yaml
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')
```