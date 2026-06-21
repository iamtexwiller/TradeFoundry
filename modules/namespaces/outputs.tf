output "namespace_names" {
  description = "Nomes completos dos namespaces criados"
  value       = { for k, v in kubernetes_namespace.environments : k => v.metadata[0].name }
}
