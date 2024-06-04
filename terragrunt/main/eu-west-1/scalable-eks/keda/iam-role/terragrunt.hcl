include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  service   = read_terragrunt_config(find_in_parent_folders("service.hcl")).locals
  component = read_terragrunt_config(find_in_parent_folders("component.hcl")).locals
  role_name = "${local.service.name}-${local.component.name}-irsa"
}

dependency "iam-policy" {
  config_path = "../iam-policy"

  # Set mock outputs that are returned when there are no outputs available before apply
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    arn = "arn:fake-iam-policy"
  }
}

dependency "eks" {
  config_path = "../../eks/"

  # Set mock outputs that are returned when there are no outputs available before apply
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    oidc_provider_arn = "arn:aws:iam::012345678901:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/FAKEFAKEFAKE12844C7333374CC09D"
  }
}

terraform {
  source = "tfr:///terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks?version=5.39.1"
}

inputs = {
  role_name        =  local.role_name

  role_policy_arns = {
    policy = dependency.iam-policy.outputs.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = dependency.eks.outputs.oidc_provider_arn
      namespace_service_accounts = ["${local.component.helm.namespace}:${local.component.helm.name}"]
    }
  }

  tags = {
    Name =  local.role_name
  }
}