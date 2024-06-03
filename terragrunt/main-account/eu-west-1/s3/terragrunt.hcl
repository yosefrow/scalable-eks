include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "tfr:///terraform-aws-modules/s3-bucket/aws?version=4.1.2"
}

inputs = {
    bucket = "yosefrow-foo-bar"
}