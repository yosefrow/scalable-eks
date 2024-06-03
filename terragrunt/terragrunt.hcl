locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
  region = read_terragrunt_config(find_in_parent_folders("region.hcl")).locals

  s3_prefix = "yosefrow"
  tf_s3_state_region = "eu-west-1"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region.name}"
  allowed_account_ids = ["${local.account.id}"]
  profile = "${local.account.aws_profile}"

  default_tags {
    tags = {
      tfPath = "${path_relative_to_include()}"
      aws_account = "${local.account.name}"
      aws_region = "${local.region.name}"
      managedBy = "Terragrunt"
    }
  }
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "${local.s3_prefix}-${local.account.name}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region     = local.tf_s3_state_region
    encrypt        = true
    profile        = local.account.aws_profile
    dynamodb_table = "${local.account.name}-state-lock"
  }
  generate = {
    path      = "backend.tf"
    profile   = local.account.aws_profile
    if_exists = "overwrite_terragrunt"
  }
}