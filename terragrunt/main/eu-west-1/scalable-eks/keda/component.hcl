locals {
  name = "keda"
  irsa = {
    service = "keda-operator"
  }
  helm = {
    name      = local.name
    namespace = local.name
  }
}
