include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  service = read_terragrunt_config(find_in_parent_folders("service.hcl")).locals
}

dependency "vpc" {
  config_path = "../vpc"

  # Configure mock outputs for the `validate` command that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  mock_outputs_allowed_terraform_commands = ["validate"]
  mock_outputs = {
    vpc_id = "fake-vpc-id"
  }
}

terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=20.13.0"
}

inputs = {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${local.service.name}-cluster"
  cluster_version = "1.29"

  # normally we don't allow public access for security reasons, 
  # see also endpoint_public_access
  cluster_endpoint_public_access = true

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets_cidr_blocks

  # EKS Managed Node Group(s)

  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.large"] # normally this list is longer
      capacity_type  = "SPOT"       # normally spot usage is used carefully to not break critical workloads
      # node_group_labels =  {
      #   "eks_node_group" = "main"
      # }
    }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  # access_entries = {
  #   # Consider adding an access entry with a policy associated
  #   example = {
  #     kubernetes_groups = []
  #     principal_arn     = "arn:aws:iam::123456789012:role/default_viewer"

  #     policy_associations = {
  #       example = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  #         access_scope = {
  #           namespaces = ["default"]
  #           type       = "namespace"
  #         }
  #       }
  #     }
  #   }
  # }
}
