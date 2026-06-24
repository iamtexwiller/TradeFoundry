resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = var.ingress_chart_version

  # No Minikube, o serviço fica como NodePort (sem custo de LoadBalancer real).
  # Em Azure, o equivalente era um Application Gateway dedicado por ambiente.
  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "controller.resources.requests.memory"
    value = "128Mi"
  }
}

resource "kubernetes_ingress_v1" "environment_ingress" {
  for_each = var.environment_namespaces

  metadata {
    name      = "tradefoundry-ingress-${each.key}"
    namespace = each.value

    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
    }
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "${each.key}.tradefoundry.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "tradefoundry-app-${each.key}"
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    # Regra adicional para o domínio público (ex: dev.tradefoundry.dev.br).
    # Sem isso, o cloudflared envia o Host real do domínio público, que o
    # Ingress não reconhece (só conhecia o host .tradefoundry.local) — isso
    # fazia o nginx cair no 404 padrão mesmo com o pod/Service saudáveis.
    dynamic "rule" {
      for_each = var.public_domain != "" ? [var.public_domain] : []

      content {
        host = "${each.key}.${rule.value}"

        http {
          path {
            path      = "/"
            path_type = "Prefix"

            backend {
              service {
                name = "tradefoundry-app-${each.key}"
                port {
                  number = 80
                }
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.nginx_ingress]
}
