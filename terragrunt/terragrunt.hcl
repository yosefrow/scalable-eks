locals {
    profile = "yosefrow"
    s3_prefix = "yosefrow"
    region = "eu-west-1"
    name = "main-terraform"
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
    region         = loca.region
    encrypt        = true
    profile        = local.profile
    dynamodb_table = "${local.name}-state-lock"
  }
}