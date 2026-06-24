# Synthetic Monitoring — testa os 3 ambientes de fora do cluster, simulando
# um usuário real acessando via internet. Detecta problemas que só aparecem
# na cadeia pública (ex: o bug de roteamento de Host no Ingress, documentado
# no README) sem precisar de verificação manual.
#
# Usa o provider "grafana" com alias "sm", configurado com credenciais
# próprias (sm_access_token / sm_url) — diferentes do token de Service
# Account usado pelo restante do projeto (dashboards/alertas).

data "grafana_synthetic_monitoring_probes" "public" {
  provider = grafana.sm
}

resource "grafana_synthetic_monitoring_check" "health" {
  for_each = var.environment_namespaces
  provider = grafana.sm

  job     = "tradefoundry-${each.key}-health"
  target  = "https://${each.key}.${var.domain}/health"
  enabled = true

  # Probes públicas próximas ao Brasil — reduz latência de borda e mede o
  # caminho mais parecido com o de um usuário real acessando o domínio.
  probes = [
    for name, probe in data.grafana_synthetic_monitoring_probes.public.probes :
    probe if contains(var.probe_names, name)
  ]

  frequency = var.check_frequency_seconds * 1000 # API espera milissegundos
  timeout   = 10000                              # 10s

  settings {
    http {
      method     = "GET"
      ip_version = "V4"

      valid_status_codes = [200]

      fail_if_body_not_matches_regexp = [
        "Status: UP"
      ]
    }
  }

  labels = {
    project     = "tradefoundry"
    environment = each.key
  }
}
