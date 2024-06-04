
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  service   = read_terragrunt_config(find_in_parent_folders("service.hcl")).locals
  component = read_terragrunt_config(find_in_parent_folders("component.hcl")).locals
}

dependency "sqs" {
  config_path = "../../sqs"

  # Set mock outputs that are returned when there are no outputs available before apply
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    queue_url = "https://sqs.eu-west-1.amazonaws.com/1234567/fake.fifo"
  }
}

terraform {
  source = "tfr:///terraform-module/release/helm?version=2.8.2"
}

inputs = {
  namespace  = local.component.helm.namespace
  repository = ""
  app = {
    name             = local.component.helm.name
    version          = "0.1.0"
    chart            = "oci://registry-1.docker.io/yosefrow/scalable-nginx"
    force_update     = true # potentially dangerous!
    cleanup_on_fail  = true # potentially dangerous!
    wait             = true
    recreate_pods    = false
    create_namespace = true
    deploy           = 1
  }

  set = [
    {
      name  = "keda.sqs.queueURL"
      value = dependency.sqs.outputs.queue_url
    }
  ]
}
