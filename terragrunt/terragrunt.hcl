locals {
    aws_profile = "yosefrow"
    s3_prefix = "yosefrow"
    region = "eu-west-1"
    name = "main-account"
}

terraform {
  extra_arguments "aws_profile" {
    commands = [
      "init",
      "apply",
      "refresh",
      "import",
      "plan",
      "taint",
      "untaint"
    ]

    env_vars = {
      AWS_PROFILE = "${local.aws_profile}"
    }
  }
}


remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
    profile   = local.aws_profile
  }

  config = {
    bucket         = "${local.s3_prefix}-${local.name}-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.region
    encrypt        = true
    profile        = local.aws_profile
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