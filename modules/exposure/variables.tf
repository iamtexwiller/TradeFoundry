variable "environment_namespaces" {
  description = "Mapa ambiente -> nome completo do namespace (vem do módulo namespaces)"
  type        = map(string)
}

variable "domain" {
  description = "Domínio raiz registrado (tradefoundry.dev.br)"
  type        = string
  default     = "tradefoundry.dev.br"
}

variable "cert_manager_chart_version" {
  description = "Versão do chart Helm do cert-manager"
  type        = string
  default     = "v1.16.2"
}

variable "cloudflared_chart_version" {
  description = "Versão do chart Helm do cloudflare-tunnel-remote"
  type        = string
  default     = "0.2.0"
}

variable "letsencrypt_server" {
  description = "Endpoint ACME do Let's Encrypt (produção ou staging)"
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "letsencrypt_email" {
  description = "E-mail de contato para avisos de expiração/renovação de certificado"
  type        = string
}

variable "cloudflare_account_email" {
  description = "E-mail da conta Cloudflare associada ao domínio"
  type        = string
}

variable "cloudflare_api_token" {
  description = "API Token da Cloudflare com permissão Zone:DNS:Edit, usado pelo cert-manager para o desafio DNS-01"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Zone ID do domínio tradefoundry.dev.br no painel Cloudflare"
  type        = string
}

variable "cloudflare_tunnel_id" {
  description = "ID do túnel Cloudflare (criado via 'cloudflared tunnel create tradefoundry')"
  type        = string
}

variable "cloudflare_tunnel_credentials_json" {
  description = "Conteúdo do arquivo credentials.json gerado ao criar o túnel"
  type        = string
  sensitive   = true
}
