output "storage_account_id" {
  description = "ID do Storage Account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Nome do Storage Account"
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "Endpoint principal do Blob Storage"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "container_hot_name" {
  description = "Nome do container Hot"
  value       = azurerm_storage_container.hot.name
}

output "container_archive_name" {
  description = "Nome do container Archive"
  value       = azurerm_storage_container.archive.name
}

output "file_share_name" {
  description = "Nome do File Share corporativo"
  value       = azurerm_storage_share.corporate.name
}
