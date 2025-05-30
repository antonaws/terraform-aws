#---------------------------------------------------------------
# EKS Blueprints Kubernetes Addons
#---------------------------------------------------------------
module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.3"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  #---------------------------------------
  # Amazon EKS Managed Add-ons
  #---------------------------------------
  eks_addons = {
    coredns = {
      preserve = true
    }
    vpc-cni = {
      preserve = true
    }
    kube-proxy = {
      preserve = true
    }
    #amazon-cloudwatch-observability = {
    #  preserve                 = true
    #  service_account_role_arn = aws_iam_role.cloudwatch_observability_role.arn
    #}
  }

  #---------------------------------------
  # ALB Controller
  #---------------------------------------
  enable_aws_load_balancer_controller = true

  #---------------------------------------
  # Kubernetes Metrics Server
  #---------------------------------------
  enable_metrics_server = true


  #---------------------------------------
  # Enable FSx for Lustre CSI Driver
  #---------------------------------------
  enable_aws_fsx_csi_driver = true

  tags = local.tags

}

#---------------------------------------------------------------
# Data on EKS Kubernetes Addons
#---------------------------------------------------------------
module "eks_data_addons" {
  source  = "aws-ia/eks-data-addons/aws"
  version = "~> 1.30" # ensure to update this to the latest/desired version

  oidc_provider_arn           = module.eks.oidc_provider_arn
  enable_nvidia_device_plugin = true

}

#---------------------------------------------------------------
# EKS Amazon CloudWatch Observability Role
#---------------------------------------------------------------
resource "aws_iam_role" "cloudwatch_observability_role" {
  name = "eks-dynamo-cloudwatch-agent-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.oidc_provider_arn
        }
        Condition = {
          StringEquals = {
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" : "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent",
            "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_observability_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.cloudwatch_observability_role.name
}

resource "aws_eks_addon" "cloudwatch" {
  cluster_name = module.eks.cluster_name
  addon_name   = "amazon-cloudwatch-observability"
  
  # Avoid recreating on each apply
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  
  # Add timeout to wait longer for creation
  timeouts {
    create = "30m"
    update = "30m"
    delete = "15m"
  }
  
  service_account_role_arn = aws_iam_role.cloudwatch_observability_role.arn
  
  # Make sure all prerequisites are ready
  depends_on = [
    module.eks_blueprints_addons,
    time_sleep.wait_for_addons
  ]
}

# Add this resource to ensure other add-ons are ready before CloudWatch
resource "time_sleep" "wait_for_addons" {
  depends_on = [module.eks_blueprints_addons]
  create_duration = "90s"
}