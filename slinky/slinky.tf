# Namespaces (must exist first)
resource "kubernetes_namespace" "slinky" {
  metadata {
    name = "slinky"
  }
}

resource "kubernetes_namespace" "slurm" {
  metadata {
    name = "slurm"
  }
}

# Slurm Operator Values (no dependency needed, purely data retrieval)
#data "http" "values_operator" {
#  url = "https://raw.githubusercontent.com/SlinkyProject/slurm-operator/refs/heads/release-0.2/helm/slurm-operator/values.yaml"
#}

# Deploy Slurm Operator first
# resource "helm_release" "slurm_operator" {
#   name             = "slurm-operator"
#   repository       = "oci://ghcr.io/slinkyproject/charts"
#   chart            = "slurm-operator"
#   version          = "0.2.0"
#   namespace        = kubernetes_namespace.slinky.metadata[0].name
#   create_namespace = true
#
#   values = [data.http.values_operator.response_body]
#
#   set {
#     name  = "image.repository"
#     value = "ghcr.io/slinkyproject/slurm-operator"
#   }
#
#   set {
#     name  = "image.tag"
#     value = "0.2.0"
#   }
#
#   timeout = 900
#
#   depends_on = [
#     kubernetes_namespace.slinky,
#     module.eks,  # Ensure the EKS cluster is ready first
#     #aws_eks_addon.fsx_csi_driver  # FSx CSI driver required first
#   ]
# }

# REMOVE THIS SECTION ENTIRELY - Not supported on EKS Kubernetes v1.29
# resource "aws_eks_addon" "fsx_csi_driver" {
#   cluster_name                 = "slinky-on-eks"
#   addon_name                   = "aws-fsx-csi-driver"
#   addon_version                = "v1.7.0-eksbuild.1"
#   resolve_conflicts_on_create  = "OVERWRITE"
#   resolve_conflicts_on_update  = "OVERWRITE"
#
#   depends_on = [module.eks]
# }

# Generate a random secret (no dependency necessary)
resource "random_password" "slurm_exporter_token" {
  length  = 64
  special = false
}

# Kubernetes secret needed by Slurm pods
resource "kubernetes_secret" "slurm_token_exporter" {
  metadata {
    name      = "slurm-token-exporter"
    namespace = kubernetes_namespace.slurm.metadata[0].name
  }

  data = {
    "auth-token" = random_password.slurm_exporter_token.result
  }

  depends_on = [
    kubernetes_namespace.slurm,
  ]
}

# Deploy Slurm only after operator and secrets are ready
# resource "helm_release" "slurm" {
#   name             = "slurm"
#   repository       = "oci://ghcr.io/slinkyproject/charts"
#   chart            = "slurm"
#   version          = "0.1.0"
#   namespace        = kubernetes_namespace.slurm.metadata[0].name
#   create_namespace = true
#
#   values = [file("${path.module}/slurm-values.yaml")]
#
#   timeout = 900
#
#   depends_on = [
#     kubernetes_namespace.slurm,
#     helm_release.slurm_operator,
#     kubernetes_secret.slurm_token_exporter,  # Ensure secret exists first
#     #aws_eks_addon.fsx_csi_driver,            # Ensure FSx CSI driver addon exists first
#   ]
# }
