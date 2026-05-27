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
