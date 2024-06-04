
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  service   = read_terragrunt_config(find_in_parent_folders("service.hcl")).locals
  component = read_terragrunt_config(find_in_parent_folders("component.hcl")).locals
}

dependency "iam-role" {
  config_path = "../iam-role"

  # Set mock outputs that are returned when there are no outputs available before apply
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    iam_role_arn = "arn:fake-iam-role"
  }
}

terraform {
  source = "tfr:///terraform-module/release/helm?version=2.8.2"
}

inputs = {
  namespace  = local.component.helm.namespace
  repository = "https://kedacore.github.io/charts"
  app = {
    name             = local.component.helm.name
    version          = "2.14.0"
    chart            = "keda"
    force_update     = true # potentially dangerous!
    cleanup_on_fail  = true # potentially dangerous!
    wait             = true
    recreate_pods    = false
    create_namespace = true
    deploy           = 1
  }

  set = [
    {
      name  = "podIdentity.aws.irsa.roleArn"
      value = dependency.iam-role.outputs.iam_role_arn
    },
    {
      name  = "podIdentity.aws.irsa.enabled"
      value = "true"
    }
  ]
}
