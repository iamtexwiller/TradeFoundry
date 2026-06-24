variable "kubeconfig_path" {
  description = "Caminho do kubeconfig local"
  type        = string
  default     = "~/.kube/config"
}

variable "kube_context" {
  description = "Context do kubectl a ser usado (ex: minikube)"
  type        = string
  default     = "minikube"
}

variable "grafana_cloud_url" {
  description = "URL da instância Grafana Cloud (ex: https://<seu-stack>.grafana.net)"
  type        = string
}

variable "grafana_cloud_api_key" {
  description = "Token de Service Account do Grafana (role Admin ou Editor) — usado para criar dashboards/folders/alertas via API. NÃO é o mesmo token gerado na tela 'Hosted Prometheus metrics' (esse último só tem permissão de escrita de métricas). Gere em: Administration > Service Accounts > Add service account > Add service account token."
  type        = string
  sensitive   = true
}

variable "grafana_cloud_prometheus_password" {
  description = "Token gerado na tela 'Connections > Hosted Prometheus metrics' (prefixo glc_...) — usado como senha do remote_write. Tem permissão só de escrita de métricas, diferente de grafana_cloud_api_key."
  type        = string
  sensitive   = true
}

variable "grafana_cloud_prometheus_remote_write_url" {
  description = "Endpoint remote_write do Prometheus no Grafana Cloud"
  type        = string
  sensitive   = true
}

variable "grafana_cloud_prometheus_username" {
  description = "Instance ID do Prometheus no Grafana Cloud"
  type        = string
  sensitive   = true
}

variable "grafana_prometheus_datasource_uid" {
  description = "UID do datasource Prometheus no Grafana Cloud"
  type        = string
}

# --- Synthetic Monitoring (opcional) ---

variable "enable_synthetic_monitoring" {
  description = "Se true, provisiona checks HTTP públicos via Grafana Synthetic Monitoring para os 3 ambientes. Requer expose_via_internet = true (os checks testam o domínio público)."
  type        = bool
  default     = false
}

variable "grafana_sm_access_token" {
  description = "Token de acesso do Synthetic Monitoring — gerado em Testing & synthetics > Synthetics > Config > Access tokens. DIFERENTE do grafana_cloud_api_key."
  type        = string
  sensitive   = true
  default     = ""
}

variable "grafana_sm_url" {
  description = "URL da API de Synthetic Monitoring para a região do seu stack (ex: https://synthetic-monitoring-api-sa-east-1.grafana.net). Visível na mesma tela onde o token é gerado."
  type        = string
  default     = "https://synthetic-monitoring-api-sa-east-1.grafana.net"
}

# --- Exposição via internet (Cloudflare Tunnel + cert-manager) ---

variable "expose_via_internet" {
  description = "Se true, provisiona o módulo de exposição (Cloudflare Tunnel + TLS real). Se false, mantém o projeto 100% local."
  type        = bool
  default     = false
}

variable "domain" {
  description = "Domínio raiz registrado (tradefoundry.dev.br)"
  type        = string
  default     = "tradefoundry.dev.br"
}

variable "letsencrypt_email" {
  description = "E-mail de contato para avisos de expiração/renovação de certificado"
  type        = string
  default     = ""
}

variable "cloudflare_account_email" {
  description = "E-mail da conta Cloudflare associada ao domínio"
  type        = string
  default     = ""
}

variable "cloudflare_api_token" {
  description = "API Token da Cloudflare (permissões: Zone:DNS:Edit) — usado para DNS-01 e criação de registros"
  type        = string
  sensitive   = true
  default     = "0000000000000000000000000000000000000000"
}

variable "cloudflare_zone_id" {
  description = "Zone ID do domínio tradefoundry.dev.br no painel Cloudflare"
  type        = string
  default     = ""
}

variable "cloudflare_tunnel_id" {
  description = "ID do túnel Cloudflare (criado via 'cloudflared tunnel create tradefoundry')"
  type        = string
  default     = ""
}

variable "cloudflare_tunnel_credentials_json" {
  description = "Conteúdo do credentials.json gerado ao criar o túnel Cloudflare"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cloudflare_origin_cert_pem" {
  description = "Conteúdo do cert.pem gerado por 'cloudflared tunnel login' (certificado de origem)"
  type        = string
  sensitive   = true
  default     = ""
}
