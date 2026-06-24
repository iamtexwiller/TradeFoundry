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

resource "kubectl_manifest" "cluster_issuer" {
  yaml_body = yamlencode({
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
  })

  # kubectl_manifest (em vez de kubernetes_manifest) evita que o Terraform
  # valide o schema do CRD durante o "plan" — o CRD do cert-manager só existe
  # no cluster depois que o helm_release.cert_manager roda de fato no "apply".
  depends_on = [helm_release.cert_manager, kubernetes_secret.cloudflare_api_token]
}

# Certificado único, válido para os três subdomínios de ambiente.
resource "kubectl_manifest" "tradefoundry_certificate" {
  yaml_body = yamlencode({
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "tradefoundry-tls"
      namespace = "cert-manager"
    }
    spec = {
      secretName = "tradefoundry-tls-secret"
      issuerRef = {
        name = "letsencrypt-dns01"
        kind = "ClusterIssuer"
      }
      dnsNames = [
        for env in keys(var.environment_namespaces) :
        "${env}.${var.domain}"
      ]
    }
  })

  depends_on = [kubectl_manifest.cluster_issuer]
}

# cloudflared — túnel outbound. Cada hostname é roteado para o Service do
# Ingress NGINX dentro do cluster (resolução interna via DNS do Kubernetes).
#
# Usamos o chart "community-charts/cloudflared" em vez do oficial
# "cloudflare/cloudflare-tunnel-remote" porque este último exige um
# TUNNEL_TOKEN (token de túnel gerenciado pelo dashboard da Cloudflare),
# diferente do credentials.json gerado via "cloudflared tunnel create"
# (fluxo via CLI, que é o que usamos aqui).
#
# Usamos tunnelSecrets.base64EncodedConfigJsonFile / base64EncodedPemFile
# (em vez de existingConfigJsonFileSecret / existingPemFileSecret) porque
# essa é a forma documentada e testada de forma consistente em todas as
# fontes oficiais do chart nesta versão; a alternativa via Secret existente
# não foi reconhecida corretamente pelo template nos testes realizados.
# O conteúdo fica visível via "helm get values" dentro do cluster local —
# risco aceitável aqui, já que o release nunca é exposto fora do cluster.
resource "helm_release" "cloudflared" {
  name       = "cloudflared"
  repository = "https://community-charts.github.io/helm-charts"
  chart      = "cloudflared"
  namespace  = "default"
  version    = var.cloudflared_chart_version

  values = [
    yamlencode({
      tunnelConfig = {
        name = "tradefoundry"
      }
      tunnelSecrets = {
        base64EncodedConfigJsonFile = base64encode(var.cloudflare_tunnel_credentials_json)
        base64EncodedPemFile        = base64encode(var.cloudflare_origin_cert_pem)
      }
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
      resources = {
        requests = {
          cpu    = "50m"
          memory = "64Mi"
        }
      }
    })
  ]

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
