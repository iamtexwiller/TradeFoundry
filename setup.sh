#binn/bash

# Cria estrutura de pastas
mkdir -p environments/dev
mkdir -p environments/staging
mkdir -p environments/prod
mkdir -p modules/01-governance
mkdir -p modules/02-networking
mkdir -p modules/03-storage
mkdir -p modules/04-compute
mkdir -p modules/05-monitoring
mkdir -p docs/assets/diagrams
mkdir -p scripts

# providers.tf raiz
cat > providers.tf << 'EOF'
terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "6bd1a287-aea3-43cd-a91c-d67a2011c002"
}
EOF

# backend.tf raiz
cat > backend.tf << 'EOF'
terraform {
  backend "azurerm" {
    resource_group_name  = "RG-TRADEFOUNDRY-TFSTATE"
    storage_account_name = "sttradefoundrytfstate"
    container_name       = "tfstate"
    key                  = "tradefoundry.tfstate"
  }
}
EOF

# Módulo 01 — Governança
cat > modules/01-governance/main.tf << 'EOF'
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_policy_definition" "require_tags" {
  name         = "tradefoundry-require-tags"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "TradeFoundry — Exigir tags obrigatórias"

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags['environment']", exists = "false" },
        { field = "tags['project']", exists = "false" },
        { field = "tags['owner']", exists = "false" }
      ]
    }
    then = {
      effect = "deny"
    }
  })
}

resource "azurerm_resource_group_policy_assignment" "require_tags" {
  name                 = "tradefoundry-require-tags"
  resource_group_id    = azurerm_resource_group.main.id
  policy_definition_id = azurerm_policy_definition.require_tags.id
  display_name         = "Exigir tags obrigatórias — TradeFoundry"
}
EOF

cat > modules/01-governance/variables.tf << 'EOF'
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
EOF

cat > modules/01-governance/outputs.tf << 'EOF'
output "resource_group_name" {
  description = "Nome do Resource Group criado"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID do Resource Group criado"
  value       = azurerm_resource_group.main.id
}

output "resource_group_location" {
  description = "Localização do Resource Group"
  value       = azurerm_resource_group.main.location
}
EOF

# Ambiente DEV
cat > environments/dev/providers.tf << 'EOF'
terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "6bd1a287-aea3-43cd-a91c-d67a2011c002"
}
EOF

cat > environments/dev/main.tf << 'EOF'
module "governance" {
  source = "../../modules/01-governance"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
EOF

cat > environments/dev/variables.tf << 'EOF'
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
EOF

cat > environments/dev/outputs.tf << 'EOF'
output "resource_group_name" {
  value = module.governance.resource_group_name
}

output "resource_group_id" {
  value = module.governance.resource_group_id
}
EOF

echo "Estrutura criada com sucesso!"
