variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
  default     = "RG-TRADEFOUNDRY-DEV"
}

variable "location" {
  description = "Região Azure"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Tags dos recursos"
  type        = map(string)
  default     = {
    environment = "dev"
    project     = "tradefoundry"
    owner       = "tex.willer"
  }
}
