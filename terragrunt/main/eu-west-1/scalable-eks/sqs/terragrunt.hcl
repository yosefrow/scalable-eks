include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  service = read_terragrunt_config(find_in_parent_folders("service.hcl")).locals
  cluster_name = "${local.service.name}-cluster"
}

dependency "vpc" {
  config_path = "../vpc"

  # Set mock outputs that are returned when there are no outputs available before apply
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
  mock_outputs = {
    vpc_id = "fake-vpc-id"
  }
}

terraform {
  source = "tfr:///terraform-aws-modules/sqs/aws?version=4.2.0"
}

inputs = {

  name = "fifo"

  fifo_queue = true
}
