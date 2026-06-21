variable "environment_namespaces" {
  description = "Mapa ambiente -> nome completo do namespace"
  type        = map(string)
}

variable "replica_count" {
  description = "Número de réplicas por ambiente — reflete prioridade de disponibilidade"
  type        = map(number)
  default = {
    dev  = 1
    cert = 1
    prod = 2
  }
}
