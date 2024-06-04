include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  service = read_terragrunt_config(find_in_parent_folders("service.hcl")).locals
  queue_name = "${local.service.name}"
}

terraform {
  source = "tfr:///terraform-aws-modules/sqs/aws?version=4.2.0"
}

inputs = {

  name = local.queue_name

  fifo_queue = true
}
