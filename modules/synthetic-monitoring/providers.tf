terraform {
  required_version = ">= 1.8.0"

  required_providers {
    grafana = {
      source                = "grafana/grafana"
      version               = "~> 3.14"
      configuration_aliases = [grafana.sm]
    }
  }
}
