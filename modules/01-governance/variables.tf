variable "resource_group_name" {
  description = "Nome do Resource Group principal"
  type        = string
}

variable "location" {
  description = "Região Azure"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Tags obrigatórias dos recursos"
  type        = map(string)
  default     = {}
}
