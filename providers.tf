terraform {
  required_version = ">= 1.8.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.14"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.45"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kube_context
}

provider "helm" {
  kubernetes {
    config_path    = var.kubeconfig_path
    config_context = var.kube_context
  }
}

provider "grafana" {
  url  = var.grafana_cloud_url
  auth = var.grafana_cloud_api_key
}

# Provider aliasado para Synthetic Monitoring — usa credenciais próprias
# (sm_access_token / sm_url), diferentes do token de Service Account usado
# pelo provider "grafana" padrão (dashboards/folders/alertas). A API de
# Synthetic Monitoring é um serviço separado dentro do Grafana Cloud.
provider "grafana" {
  alias           = "sm"
  sm_access_token = var.grafana_sm_access_token
  sm_url          = var.grafana_sm_url
}

provider "cloudflare" {
  # O provider valida o FORMATO do token já na inicialização, mesmo que
  # nenhum recurso Cloudflare seja de fato criado (módulo "exposure" com
  # count = 0 quando expose_via_internet = false). Por isso a variável
  # tem um default placeholder com formato válido — ver variables.tf.
  api_token = var.cloudflare_api_token
}

# kubectl_manifest (usado para ClusterIssuer/Certificate do cert-manager)
# não valida o schema do CRD durante "plan" — diferente de kubernetes_manifest,
# que exige que o CRD já exista no cluster nesse momento. Necessário porque
# o CRD do cert-manager só é instalado durante o "apply" (via helm_release).
provider "kubectl" {
  config_path      = var.kubeconfig_path
  config_context   = var.kube_context
  load_config_file = true
}
