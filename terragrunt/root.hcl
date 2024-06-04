locals {
  account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
  region  = read_terragrunt_config(find_in_parent_folders("region.hcl")).locals

  # Unique S3 Prefix to ensure state buckets don't conflict
  tf_state_s3_prefix   =  get_env("TF_STATE_S3_PREFIX", "yosefrow")
  tf_state_region      = "eu-west-1"
  kubeconfig           = "${get_repo_root()}/terragrunt/kubeconfig"
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
      tg_path = "${path_relative_to_include()}"
      aws_account = "${local.account.name}"
      aws_region = "${local.region.name}"
      environment = "${local.account.environment}"
      managed_by = "Terragrunt"
    }
  }
}
EOF
}

generate "helm-provider" {
  path      = "helm-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "helm" {
  kubernetes {
    config_path = "${local.kubeconfig}"
  }
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "${local.tf_state_s3_prefix}-${local.account.name}-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.tf_state_region
    encrypt        = true
    profile        = local.account.aws_profile
    dynamodb_table = "${local.account.name}-terraform-state-lock"
  }
  generate = {
    path      = "backend.tf"
    profile   = local.account.aws_profile
    if_exists = "overwrite_terragrunt"
  }
}
