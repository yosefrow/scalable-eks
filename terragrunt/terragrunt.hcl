locals {
    profile = "yosefrow"
    s3_prefix = "yosefrow"
    region = "eu-west-1"
    name = "main-account"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }  
  config = {
    bucket         = "${local.s3_prefix}-${local.name}-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    profile        = local.profile
    dynamodb_table = "${local.name}-state-lock"
  }
  default_tags {
    tags = {
      tfProvider = local.name
      tfPath = "${path_relative_to_include()}"
      region = local.region
      managedBy = "Terragrunt"
    }
  }
}