# ─────────────────────────────────────────
# TradeFoundry — Módulo 03: Storage
# ─────────────────────────────────────────

# Storage Account principal
resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  blob_properties {
    versioning_enabled = true
    delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

# Container — Hot (dados acessados frequentemente)
resource "azurerm_storage_container" "hot" {
  name                  = "hot"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Container — Archive (dados históricos)
resource "azurerm_storage_container" "archive" {
  name                  = "archive"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Container — Logs
resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Lifecycle Management — tiering automático
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "hot-to-cool"
    enabled = true
    filters {
      prefix_match = ["hot/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
      }
    }
  }

  rule {
    name    = "cool-to-archive"
    enabled = true
    filters {
      prefix_match = ["hot/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
    }
  }

  rule {
    name    = "delete-old-logs"
    enabled = true
    filters {
      prefix_match = ["logs/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
    }
  }
}

# Azure File Share — compartilhamento corporativo
resource "azurerm_storage_share" "corporate" {
  name                 = "corporate"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 50
}
