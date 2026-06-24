variable "environment_namespaces" {
  description = "Mapa ambiente -> nome completo do namespace (vem do módulo namespaces)"
  type        = map(string)
}

variable "domain" {
  description = "Domínio público para montar a URL de cada check (ex: tradefoundry.dev.br)"
  type        = string
}

variable "probe_names" {
  description = "Nomes das probes públicas da Grafana a usar (ex: [\"SaoPaulo\"]). Ver lista completa em Synthetic Monitoring > Probes."
  type        = list(string)
  default     = ["SaoPaulo"]
}

variable "check_frequency_seconds" {
  description = "Frequência de execução de cada check, em segundos"
  type        = number
  default     = 900
}
