locals {
  name = "keda"
  helm = {
    name      = local.name
    namespace = local.name
  }
}