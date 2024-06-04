
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
  mock_outputs_allowed_terraform_commands = ["validate"]
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
    name          = local.component.helm.name
    chart         = "keda"
    version       = "2.14.0"
    force_update  = true
    wait          = true
    recreate_pods = false
  }
  values = [
    templatefile("${get_terragrunt_dir()}/values.yaml", {
      keda_operator_role_arn = dependency.iam-role.outputs.iam_role_arn
    }),
  ]
}
