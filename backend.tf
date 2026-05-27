terraform {
  backend "azurerm" {
    resource_group_name  = "RG-TRADEFOUNDRY-TFSTATE"
    storage_account_name = "sttradefoundrytfstate"
    container_name       = "tfstate"
    key                  = "tradefoundry.tfstate"
  }
}
