variable "environment_namespaces" {
  description = "Mapa ambiente -> nome completo do namespace"
  type        = map(string)
}

variable "ingress_chart_version" {
  description = "Versão do chart Helm do ingress-nginx"
  type        = string
  default     = "4.11.3"
}

variable "public_domain" {
  description = "Domínio público para exposição via internet (ex: tradefoundry.dev.br). Vazio = só o host .local é configurado."
  type        = string
  default     = ""
}
