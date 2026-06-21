variable "prometheus_chart_version" {
  description = "Versão do chart kube-prometheus-stack"
  type        = string
  default     = "65.5.0"
}

variable "grafana_cloud_prometheus_remote_write_url" {
  description = "Endpoint remote_write do Grafana Cloud (obtido no painel de Connections > Prometheus)"
  type        = string
  sensitive   = true
}

variable "grafana_cloud_prometheus_username" {
  description = "Instance ID do Prometheus no Grafana Cloud"
  type        = string
  sensitive   = true
}

variable "grafana_cloud_prometheus_password" {
  description = "Token gerado em Connections > Hosted Prometheus metrics (prefixo glc_...), usado como senha do remote_write"
  type        = string
  sensitive   = true
}

variable "grafana_prometheus_datasource_uid" {
  description = "UID do datasource Prometheus já configurado no Grafana Cloud"
  type        = string
}
