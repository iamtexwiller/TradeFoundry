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

provider "cloudflare" {
  # O provider valida o FORMATO do token já na inicialização, mesmo que
  # nenhum recurso Cloudflare seja de fato criado (módulo "exposure" com
  # count = 0 quando expose_via_internet = false). Por isso a variável
  # tem um default placeholder com formato válido — ver variables.tf.
  api_token = var.cloudflare_api_token
}
