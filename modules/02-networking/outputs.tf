output "vnet_id" {
  description = "ID da Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Nome da Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_app_id" {
  description = "ID da subnet App"
  value       = azurerm_subnet.app.id
}

output "subnet_data_id" {
  description = "ID da subnet Data"
  value       = azurerm_subnet.data.id
}

output "subnet_mgmt_id" {
  description = "ID da subnet Management"
  value       = azurerm_subnet.mgmt.id
}

output "bastion_name" {
  description = "Nome do Azure Bastion"
  value       = azurerm_bastion_host.main.name
}
