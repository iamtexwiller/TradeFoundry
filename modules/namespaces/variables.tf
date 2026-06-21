variable "environments" {
  description = "Lista de ambientes a serem provisionados como namespaces"
  type        = list(string)
  default     = ["dev", "cert", "prod"]
}

variable "environment_descriptions" {
  description = "Descrição de propósito de cada ambiente"
  type        = map(string)
  default = {
    dev  = "Desenvolvimento e integração contínua"
    cert = "Homologação e testes de aceitação"
    prod = "Produção — simulação do ambiente final"
  }
}

variable "quotas" {
  description = "ResourceQuota por ambiente — intencionalmente menores em dev, maiores em prod"
  type = map(object({
    cpu_requests    = string
    cpu_limits      = string
    memory_requests = string
    memory_limits   = string
    max_pods        = string
  }))

  default = {
    dev = {
      cpu_requests    = "500m"
      cpu_limits      = "1"
      memory_requests = "512Mi"
      memory_limits   = "1Gi"
      max_pods        = "10"
    }
    cert = {
      cpu_requests    = "500m"
      cpu_limits      = "1"
      memory_requests = "512Mi"
      memory_limits   = "1Gi"
      max_pods        = "10"
    }
    prod = {
      cpu_requests    = "1"
      cpu_limits      = "2"
      memory_requests = "1Gi"
      memory_limits   = "2Gi"
      max_pods        = "20"
    }
  }
}
