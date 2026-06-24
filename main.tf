module "namespaces" {
  source = "./modules/namespaces"
}

module "ingress" {
  source = "./modules/ingress"

  environment_namespaces = module.namespaces.namespace_names
  public_domain          = var.expose_via_internet ? var.domain : ""

  depends_on = [module.namespaces]
}

module "workload_demo" {
  source = "./modules/workload-demo"

  environment_namespaces = module.namespaces.namespace_names

  depends_on = [module.namespaces]
}

module "observability" {
  source = "./modules/observability"

  grafana_cloud_prometheus_remote_write_url = var.grafana_cloud_prometheus_remote_write_url
  grafana_cloud_prometheus_username         = var.grafana_cloud_prometheus_username
  grafana_cloud_prometheus_password         = var.grafana_cloud_prometheus_password
  grafana_prometheus_datasource_uid         = var.grafana_prometheus_datasource_uid

  depends_on = [module.namespaces]
}

# Módulo opcional — só provisiona Cloudflare Tunnel + cert-manager quando
# expose_via_internet = true. Mantém o projeto utilizável 100% local por padrão.
module "exposure" {
  source = "./modules/exposure"
  count  = var.expose_via_internet ? 1 : 0

  environment_namespaces             = module.namespaces.namespace_names
  domain                             = var.domain
  letsencrypt_email                  = var.letsencrypt_email
  cloudflare_account_email           = var.cloudflare_account_email
  cloudflare_api_token               = var.cloudflare_api_token
  cloudflare_zone_id                 = var.cloudflare_zone_id
  cloudflare_tunnel_id               = var.cloudflare_tunnel_id
  cloudflare_tunnel_credentials_json = var.cloudflare_tunnel_credentials_json
  cloudflare_origin_cert_pem         = var.cloudflare_origin_cert_pem

  depends_on = [module.namespaces, module.ingress]
}

# Módulo opcional — só provisiona checks de Synthetic Monitoring quando
# enable_synthetic_monitoring = true. Os checks testam o domínio público,
# então só fazem sentido com expose_via_internet = true também.
module "synthetic_monitoring" {
  source = "./modules/synthetic-monitoring"
  count  = var.enable_synthetic_monitoring ? 1 : 0

  # Módulos com count que usam um provider com alias (não o default) precisam
  # receber esse provider explicitamente — não basta o módulo filho referenciar
  # "grafana.sm" internamente.
  providers = {
    grafana.sm = grafana.sm
  }

  environment_namespaces = module.namespaces.namespace_names
  domain                 = var.domain

  depends_on = [module.exposure]
}
