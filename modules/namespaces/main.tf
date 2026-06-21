resource "kubernetes_namespace" "environments" {
  for_each = toset(var.environments)

  metadata {
    name = "tradefoundry-${each.value}"

    labels = {
      project     = "tradefoundry"
      environment = each.value
      managed-by  = "terraform"
    }

    annotations = {
      "tradefoundry.io/description" = lookup(var.environment_descriptions, each.value, "")
    }
  }
}

resource "kubernetes_resource_quota" "default" {
  for_each = toset(var.environments)

  metadata {
    name      = "tradefoundry-quota"
    namespace = kubernetes_namespace.environments[each.value].metadata[0].name
  }

  spec {
    hard = {
      "requests.cpu"    = var.quotas[each.value].cpu_requests
      "requests.memory" = var.quotas[each.value].memory_requests
      "limits.cpu"      = var.quotas[each.value].cpu_limits
      "limits.memory"   = var.quotas[each.value].memory_limits
      "pods"            = var.quotas[each.value].max_pods
    }
  }
}
