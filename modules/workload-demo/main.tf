resource "kubernetes_deployment" "app" {
  for_each = var.environment_namespaces

  metadata {
    name      = "tradefoundry-app-${each.key}"
    namespace = each.value

    labels = {
      app         = "tradefoundry-app"
      environment = each.key
    }
  }

  spec {
    replicas = var.replica_count[each.key]

    selector {
      match_labels = {
        app         = "tradefoundry-app"
        environment = each.key
      }
    }

    template {
      metadata {
        labels = {
          app         = "tradefoundry-app"
          environment = each.key
        }

        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/port"   = "80"
        }
      }

      spec {
        container {
          name  = "nginx"
          image = "nginxinc/nginx-unprivileged:1.27-alpine"

          port {
            container_port = 8080
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }
            limits = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          volume_mount {
            name       = "healthz-config"
            mount_path = "/usr/share/nginx/html/healthz"
            sub_path   = "healthz"
          }
        }

        volume {
          name = "healthz-config"
          config_map {
            name = kubernetes_config_map.healthz[each.key].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_config_map" "healthz" {
  for_each = var.environment_namespaces

  metadata {
    name      = "tradefoundry-healthz-${each.key}"
    namespace = each.value
  }

  data = {
    healthz = "ok"
  }
}

resource "kubernetes_service" "app" {
  for_each = var.environment_namespaces

  metadata {
    name      = "tradefoundry-app-${each.key}"
    namespace = each.value
  }

  spec {
    selector = {
      app         = "tradefoundry-app"
      environment = each.key
    }

    port {
      port        = 80
      target_port = 8080
    }
  }
}
