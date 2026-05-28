variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Região Azure"
  type        = string
  default     = "eastus2"
}

variable "vnet_name" {
  description = "Nome da Virtual Network"
  type        = string
  default     = "vnet-tradefoundry"
}

variable "vnet_cidr" {
  description = "CIDR da Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_app_cidr" {
  description = "CIDR da subnet de aplicações"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_data_cidr" {
  description = "CIDR da subnet de dados"
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_mgmt_cidr" {
  description = "CIDR da subnet de management"
  type        = string
  default     = "10.0.3.0/24"
}

variable "subnet_bastion_cidr" {
  description = "CIDR da subnet do Bastion"
  type        = string
  default     = "10.0.4.0/24"
}

variable "tags" {
  description = "Tags dos recursos"
  type        = map(string)
  default     = {}
}
