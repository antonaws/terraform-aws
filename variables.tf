variable "name" {
  description = "Name of the VPC and EKS Cluster"
  default     = "eks-static-cluster"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = ""
}

variable "eks_cluster_version" {
  description = "EKS Cluster version"
  default     = "1.29"
  type        = string
}

# VPC with 2046 IPs (10.1.0.0/21) and 2 AZs
variable "vpc_cidr" {
  description = "VPC CIDR"
  default     = "10.1.0.0/21"
  type        = string
}

# RFC6598 range 100.64.0.0/10
# Note you can only /16 range to VPC. You can add multiples of /16 if required
variable "secondary_cidr_blocks" {
  description = "Secondary CIDR blocks to be attached to VPC"
  default     = ["100.64.0.0/16"]
  type        = list(string)
}

# For vpc.tf - define missing variables
variable "az_count" {
  description = "Number of availability zones to use"
  default     = 2
  type        = number
}

variable "enable_secondary_cidr" {
  description = "Enable secondary CIDR blocks for pod IPs"
  default     = true
  type        = bool
}

variable "secondary_cidr" {
  description = "Secondary CIDR block"
  default     = "100.64.0.0/16"
  type        = string
}

variable "create_fsx_security_group" {
  description = "Create security group for FSx for Lustre"
  default     = true
  type        = bool
}

variable "tags" {
  description = "Additional tags for all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-static-cluster"
}

variable "create_fsx_resources" {
  description = "Whether to create FSx for Lustre resources"
  type        = bool
  default     = false  # Set default to false to skip FSx resources
}
