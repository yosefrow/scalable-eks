include "root" {
    path = find_in_parent_folders()
}

locals {
    account = read_terragrunt_config(find_in_parent_folders("account.hcl")).locals
    region = read_terragrunt_config(find_in_parent_folders("region.hcl")).locals
    service = read_terragrunt_config(find_in_parent_folders("service.hcl")).locals
}

terraform {
    source = "tfr:///terraform-aws-modules/vpc/aws?version=5.8.1"
}

inputs = {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.service.name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
}