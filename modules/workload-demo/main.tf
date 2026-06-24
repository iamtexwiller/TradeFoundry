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
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds        = 5
          }

          # /health é servido como JSON estático via ConfigMap. O bloco
          # "default.conf" reescreve a config padrão do nginx para que essa
          # rota responda com Content-Type application/json, em vez do
          # application/octet-stream padrão para arquivos sem extensão.
          volume_mount {
            name       = "health-page"
            mount_path = "/usr/share/nginx/html/health.json"
            sub_path   = "health.json"
          }

          volume_mount {
            name       = "nginx-extra-config"
            mount_path = "/etc/nginx/conf.d/default.conf"
            sub_path   = "default.conf"
          }
        }

        volume {
          name = "health-page"
          config_map {
            name = kubernetes_config_map.health[each.key].metadata[0].name
          }
        }

        volume {
          name = "nginx-extra-config"
          config_map {
            name = kubernetes_config_map.nginx_extra_config[each.key].metadata[0].name
          }
        }
      }
    }
  }
}

# JSON simples servido em /health — substitui a versão anterior em HTML,
# que apresentou comportamento inconsistente via HTTP/2 (corpo vazio em
# alguns clientes/caminhos). JSON é mais previsível de servir e de validar.
resource "kubernetes_config_map" "health" {
  for_each = var.environment_namespaces

  metadata {
    name      = "tradefoundry-health-${each.key}"
    namespace = each.value
  }

  data = {
    "health.json" = jsonencode({
      message = "Ambiente ${upper(each.key)} - Status: UP"
    })
  }
}

# Substitui o default.conf inteiro da imagem nginx-unprivileged, incluindo
# o bloco "server" — um bloco "location" não pode existir sozinho dentro de
# /etc/nginx/conf.d/ (precisa estar dentro de um "server {}"), por isso não
# basta adicionar um .conf extra: é necessário substituir o arquivo principal.
# Criado por ambiente porque ConfigMaps são recursos namespaced — cada
# Deployment só pode montar um ConfigMap do seu próprio namespace.
resource "kubernetes_config_map" "nginx_extra_config" {
  for_each = var.environment_namespaces

  metadata {
    name      = "tradefoundry-nginx-extra-config"
    namespace = each.value
  }

  data = {
    "default.conf" = <<-EOT
      server {
        listen 8080;
        server_name _;

        location = /health {
          default_type application/json;
          alias /usr/share/nginx/html/health.json;
        }

        location / {
          root /usr/share/nginx/html;
          index index.html;
        }
      }
    EOT
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
