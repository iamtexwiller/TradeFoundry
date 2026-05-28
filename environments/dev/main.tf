module "governance" {
  source = "../../modules/01-governance"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

module "networking" {
  source = "../../modules/02-networking"

  resource_group_name = module.governance.resource_group_name
  location            = var.location
  tags                = var.tags
}
