resource "random_string" "cyclelocker_suffix" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_storage_account" "cyclelocker" {
  account_replication_type      = var.storage_replication_type
  account_tier                  = var.storage_account_tier
  location                      = local.effective_location
  min_tls_version               = "TLS1_2"
  name                          = substr("cclock${random_string.cyclelocker_suffix.result}", 0, 24)
  public_network_access_enabled = false
  resource_group_name           = data.azurerm_resource_group.foundation.name
  tags                          = local.common_tags

  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = true

  blob_properties {
    versioning_enabled = true
  }

  network_rules {
    bypass         = ["AzureServices"]
    default_action = "Deny"
  }
}

resource "azurerm_storage_container" "cyclelocker" {
  name                  = "cyclelocker"
  storage_account_id    = azurerm_storage_account.cyclelocker.id
  container_access_type = "private"
}
