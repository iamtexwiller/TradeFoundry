# Exposição real via internet — substitui o par Application Gateway + IP público do Azure.
#
# Componentes:
#   1. cloudflared (Helm) — túnel outbound do cluster até a borda do Cloudflare.
#      Não exige porta aberta no roteador nem IP fixo/residencial exposto.
#   2. cert-manager (Helm) — emissão de certificados TLS reais via Let's Encrypt.
#   3. ClusterIssuer com desafio DNS-01 — escolhido em vez de HTTP-01 porque
#      o domínio tradefoundry.dev.br está no Cloudflare, e DNS-01 não depende
#      da porta 80 estar acessível (problema já enfrentado e documentado em
#      outro projeto anterior do autor, com cert-manager em ambiente multi-namespace).
#   4. Cloudflare DNS records — subdomínios por ambiente apontando para o túnel.

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  version          = var.cert_manager_chart_version

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

# Secret com o token da Cloudflare, usado pelo cert-manager para resolver o
# desafio DNS-01 (criar/remover registros TXT automaticamente).
resource "kubernetes_secret" "cloudflare_api_token" {
  metadata {
    name      = "cloudflare-api-token"
    namespace = "cert-manager"
  }

  data = {
    api-token = var.cloudflare_api_token
  }

  depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-dns01"
    }
    spec = {
      acme = {
        server = var.letsencrypt_server
        email  = var.letsencrypt_email
        privateKeySecretRef = {
          name = "letsencrypt-dns01-account-key"
        }
        solvers = [
          {
            dns01 = {
              cloudflare = {
                email = var.cloudflare_account_email
                apiTokenSecretRef = {
                  name = kubernetes_secret.cloudflare_api_token.metadata[0].name
                  key  = "api-token"
                }
              }
            }
          }
        ]
      }
    }
  }

  depends_on = [helm_release.cert_manager, kubernetes_secret.cloudflare_api_token]
}

# Certificado único, válido para os três subdomínios de ambiente.
resource "kubernetes_manifest" "tradefoundry_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "tradefoundry-tls"
      namespace = "cert-manager"
    }
    spec = {
      secretName = "tradefoundry-tls-secret"
      issuerRef = {
        name = kubernetes_manifest.cluster_issuer.manifest.metadata.name
        kind = "ClusterIssuer"
      }
      dnsNames = [
        for env in keys(var.environment_namespaces) :
        "${env}.${var.domain}"
      ]
    }
  }

  depends_on = [kubernetes_manifest.cluster_issuer]
}

# cloudflared — túnel outbound. Cada hostname é roteado para o Service do
# Ingress NGINX dentro do cluster (resolução interna via DNS do Kubernetes).
resource "kubernetes_secret" "cloudflared_credentials" {
  metadata {
    name      = "cloudflared-credentials"
    namespace = "default"
  }

  data = {
    "credentials.json" = var.cloudflare_tunnel_credentials_json
  }
}

resource "kubernetes_config_map" "cloudflared_config" {
  metadata {
    name      = "cloudflared-config"
    namespace = "default"
  }

  data = {
    "config.yaml" = yamlencode({
      tunnel           = var.cloudflare_tunnel_id
      credentials-file = "/etc/cloudflared/creds/credentials.json"
      ingress = concat(
        [
          for env in keys(var.environment_namespaces) : {
            hostname = "${env}.${var.domain}"
            service  = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80"
          }
        ],
        [
          { service = "http_status:404" } # catch-all obrigatório do cloudflared
        ]
      )
    })
  }
}

resource "helm_release" "cloudflared" {
  name       = "cloudflared"
  repository = "https://cloudflare.github.io/helm-charts"
  chart      = "cloudflare-tunnel-remote"
  namespace  = "default"
  version    = var.cloudflared_chart_version

  values = [
    yamlencode({
      cloudflare = {
        tunnelId = var.cloudflare_tunnel_id
        secret   = kubernetes_secret.cloudflared_credentials.metadata[0].name
        ingress = concat(
          [
            for env in keys(var.environment_namespaces) : {
              hostname = "${env}.${var.domain}"
              service  = "http://ingress-nginx-controller.ingress-nginx.svc.cluster.local:80"
            }
          ],
          [
            { service = "http_status:404" }
          ]
        )
      }
      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
      }
    })
  ]

  depends_on = [kubernetes_secret.cloudflared_credentials, kubernetes_config_map.cloudflared_config]
}

# Registros DNS — gerenciados como código via provider Cloudflare.
resource "cloudflare_record" "environment_subdomains" {
  for_each = var.environment_namespaces

  zone_id = var.cloudflare_zone_id
  name    = each.key
  type    = "CNAME"
  content = "${var.cloudflare_tunnel_id}.cfargotunnel.com"
  proxied = true
}
