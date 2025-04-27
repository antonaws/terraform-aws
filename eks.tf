#---------------------------------------------------------------
# EKS Cluster with Static Node Groups
#---------------------------------------------------------------
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15"

  cluster_name                   = local.name
  cluster_version                = var.eks_cluster_version
  cluster_endpoint_public_access = true
  vpc_id                         = module.vpc.vpc_id
  subnet_ids                     = module.vpc.private_subnets
  manage_aws_auth_configmap      = true

  #---------------------------------------
  # Extend cluster security group rules
  #---------------------------------------
  cluster_security_group_additional_rules = {
    ingress_nodes_ephemeral_ports_tcp = {
      description                = "Nodes on ephemeral ports"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "ingress"
      source_node_security_group = true
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    
    ingress_cluster_to_node_all_traffic = {
      description                   = "Cluster API to Nodegroup all traffic"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }

  eks_managed_node_group_defaults = {
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  #---------------------------------------
  # Static Node Groups Configuration
  #---------------------------------------
  eks_managed_node_groups = {
    # Core node group for system workloads - STATIC
    core_node_group = {
      name        = "core-node-group"
      description = "EKS Core node group for hosting critical add-ons"
      
      subnet_ids = compact([for subnet_id, cidr_block in zipmap(module.vpc.private_subnets, module.vpc.private_subnets_cidr_blocks) :
        substr(cidr_block, 0, 4) == "100." ? subnet_id : null]
      )

      # STATIC CONFIGURATION - Same min/max/desired
      min_size     = 3
      max_size     = 3
      desired_size = 3

      instance_types = ["m5.xlarge"]

      ebs_optimized = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 100
            volume_type = "gp3"
          }
        }
      }

      labels = {
        WorkerType    = "ON_DEMAND"
        NodeGroupType = "core"
      }

      tags = merge(local.tags, {
        Name = "core-node-grp"
      })
    }

    # Compute node group for general workloads - STATIC
    compute_node_group = {
      name        = "compute-node-grp"
      description = "EKS Compute node group for general workloads"
      
      subnet_ids = compact([for subnet_id, cidr_block in zipmap(module.vpc.private_subnets, module.vpc.private_subnets_cidr_blocks) :
        substr(cidr_block, 0, 4) == "100." ? subnet_id : null]
      )

      # STATIC CONFIGURATION - Same min/max/desired
      min_size     = 3
      max_size     = 3
      desired_size = 3

      instance_types = ["m5.xlarge"]

      ebs_optimized = true
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 100
            volume_type = "gp3"
          }
        }
      }

      labels = {
        WorkerType    = "ON_DEMAND"
        NodeGroupType = "compute"
      }

      tags = merge(local.tags, {
        Name = "compute-node-grp"
      })
    }

    # GPU node group - STATIC with proper GPU instance type
    gpu_node_group = {
      name        = "gpu-node-grp"
      description = "EKS GPU node group with g6e instances"

      subnet_ids = compact([
        for subnet_id, cidr_block in zipmap(module.vpc.private_subnets, module.vpc.private_subnets_cidr_blocks) :
        substr(cidr_block, 0, 4) == "100." ? subnet_id : null
      ])

      # STATIC CONFIGURATION - Same min/max/desired
      min_size     = 2
      max_size     = 2
      desired_size = 2

      # Proper GPU configuration
      ami_type       = "AL2_x86_64_GPU"
      instance_types = ["g6e.xlarge"] # G6e GPU instance type

      labels = {
        WorkerType     = "ON_DEMAND"
        NodeGroupType  = "gpu"
        "nvidia.com/gpu" = "true"
      }

      # Taints to ensure only GPU workloads run on these nodes
      taints = [{
        key    = "nvidia.com/gpu"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]

      tags = merge(local.tags, {
        Name = "gpu-node-grp"
      })
    }
  }
}