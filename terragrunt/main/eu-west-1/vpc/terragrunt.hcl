include "root" {
    path = find_in_parent_folders()
}

locals {
    account = find_in_parent_folders("account.hcl")
    region = find_in_parent_folders("region.hcl")
}

terraform {
    source = "tfr:///terraform-aws-modules/vpc/aws?version=5.8.1"
}

inputs = {}