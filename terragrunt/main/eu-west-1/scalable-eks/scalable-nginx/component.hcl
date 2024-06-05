locals {
  name = "scalable-nginx"
  helm = {
    name      = local.name
    namespace = local.name
  }
}