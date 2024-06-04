locals {
  name        = "main"
  id          = "203513363151"
  aws_profile = get_env("AWS_PROFILE_MAIN", "yosefrow-main")
  environment = "dev"
}