variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Região Azure"
  type        = string
  default     = "eastus2"
}

variable "storage_account_name" {
  description = "Nome do Storage Account (apenas letras minúsculas e números)"
  type        = string
}

variable "tags" {
  description = "Tags dos recursos"
  type        = map(string)
  default     = {}
}
