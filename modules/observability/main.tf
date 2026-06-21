# Observabilidade — substitui Log Analytics Workspace + Application Insights do Azure.
#
# Em vez de um agente proprietário, usamos:
#   - kube-prometheus-stack (Helm) para coletar métricas do cluster local
#   - remote_write para enviar as métricas ao Grafana Cloud (free tier: 10k séries, 14 dias retenção)
#   - O dashboard e o alerta são definidos como código (Terraform), não criados manualmente na UI
#
# O namespace "monitoring" é criado explicitamente aqui (em vez de via
# create_namespace=true do helm_release) porque o Helm release referencia
# o Secret de credenciais no seu values.yaml, e o Secret precisa existir
# dentro do namespace "monitoring" — criar o namespace só como efeito
# colateral do Helm gera uma dependência circular implícita.
resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_secret" "grafana_cloud_credentials" {
  metadata {
    name      = "grafana-cloud-credentials"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    username = var.grafana_cloud_prometheus_username
    password = var.grafana_cloud_prometheus_password
  }

  depends_on = [kubernetes_namespace.monitoring]
}

resource "helm_release" "kube_prometheus_stack" {
  name             = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  create_namespace = false
  version          = var.prometheus_chart_version

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          remoteWrite = [
            {
              url = var.grafana_cloud_prometheus_remote_write_url
              basicAuth = {
                username = {
                  name = kubernetes_secret.grafana_cloud_credentials.metadata[0].name
                  key  = "username"
                }
                password = {
                  name = kubernetes_secret.grafana_cloud_credentials.metadata[0].name
                  key  = "password"
                }
              }
            }
          ]
          resources = {
            requests = {
              cpu    = "200m"
              memory = "400Mi"
            }
          }
        }
      }
      # Desativa componentes pesados não essenciais para manter o cluster local leve
      grafana = {
        enabled = false # usamos o Grafana Cloud, não o local
      }
      alertmanager = {
        enabled = true
      }
    })
  ]

  depends_on = [kubernetes_secret.grafana_cloud_credentials]
}

# Dashboard provisionado como código — equivalente declarativo ao Application Insights workbook
resource "grafana_dashboard" "tradefoundry_overview" {
  config_json = jsonencode({
    title = "TradeFoundry — Visão Geral dos Ambientes"
    tags  = ["tradefoundry", "terraform-managed"]
    panels = [
      {
        id      = 1
        title   = "Pods disponíveis por ambiente"
        type    = "timeseries"
        gridPos = { h = 8, w = 12, x = 0, y = 0 }
        targets = [
          {
            expr = "sum(kube_pod_status_ready{namespace=~\"tradefoundry-.*\"}) by (namespace)"
          }
        ]
      },
      {
        id      = 2
        title   = "Uso de CPU por ambiente"
        type    = "timeseries"
        gridPos = { h = 8, w = 12, x = 12, y = 0 }
        targets = [
          {
            expr = "sum(rate(container_cpu_usage_seconds_total{namespace=~\"tradefoundry-.*\"}[5m])) by (namespace)"
          }
        ]
      },
      {
        id      = 3
        title   = "Nodes do cluster (status)"
        type    = "stat"
        gridPos = { h = 6, w = 24, x = 0, y = 8 }
        targets = [
          {
            expr = "sum(kube_node_status_condition{condition=\"Ready\", status=\"true\"})"
          }
        ]
      }
    ]
    schemaVersion = 39
  })
}

# Alerta — equivalente ao "alert-tradefoundry-node-down" do projeto original em Azure
resource "grafana_rule_group" "tradefoundry_alerts" {
  name             = "tradefoundry-alerts"
  folder_uid       = grafana_folder.tradefoundry.uid
  interval_seconds = 60

  rule {
    name      = "tradefoundry-node-down"
    condition = "C"

    data {
      ref_id = "A"
      relative_time_range {
        from = 600
        to   = 0
      }
      datasource_uid = var.grafana_prometheus_datasource_uid
      model = jsonencode({
        expr = "sum(kube_node_status_condition{condition=\"Ready\", status=\"true\"})"
      })
    }

    data {
      ref_id = "C"
      relative_time_range {
        from = 600
        to   = 0
      }
      datasource_uid = "__expr__"
      model = jsonencode({
        type       = "threshold"
        expression = "A"
        conditions = [
          {
            evaluator = {
              type   = "lt"
              params = [1]
            }
          }
        ]
      })
    }

    no_data_state  = "Alerting"
    exec_err_state = "Alerting"
    for            = "2m"

    annotations = {
      summary = "Nenhum node Ready encontrado no cluster TradeFoundry"
    }

    labels = {
      severity = "critical"
      project  = "tradefoundry"
    }
  }
}

resource "grafana_folder" "tradefoundry" {
  title = "TradeFoundry"
}
