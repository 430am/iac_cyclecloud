resource "azurerm_private_dns_zone" "blob" {
  name                = local.dns_names.private_dns_zone_blob
  resource_group_name = azurerm_resource_group.cyclecloud.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "bootdiag-blob-link"
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  resource_group_name   = azurerm_resource_group.cyclecloud.name
  virtual_network_id    = azurerm_virtual_network.cyclecloud.id
}

resource "azurerm_private_endpoint" "bootdiag_blob" {
  location            = var.location
  name                = "pe-${random_pet.naming.id}-bootdiag-blob"
  resource_group_name = azurerm_resource_group.cyclecloud.name
  subnet_id           = azurerm_subnet.cyclecloud["private_endpoints"].id

  private_service_connection {
    is_manual_connection           = false
    name                           = "bootdiag-blob-connection"
    private_connection_resource_id = azurerm_storage_account.bootdiag.id
    subresource_names              = ["blob"]
  }

  tags = local.common_tags
}

resource "azurerm_storage_account" "bootdiag" {
  # Required
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.location
  name                     = "bootdiag${random_pet.naming.id}"
  resource_group_name      = azurerm_resource_group.cyclecloud.name

  # Optional
  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  tags                            = local.common_tags
}

resource "azurerm_monitor_diagnostic_setting" "bastion_host" {
  name                       = "diag-${azurerm_bastion_host.cyclecloud.name}"
  storage_account_id         = azurerm_storage_account.bootdiag.id
  target_resource_id         = azurerm_bastion_host.cyclecloud.id

  enabled_log {
    category = "BastionAuditLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nat_gateway" {
  name               = "diag-${azurerm_nat_gateway.cyclecloud.name}"
  storage_account_id = azurerm_storage_account.bootdiag.id
  target_resource_id = azurerm_nat_gateway.cyclecloud.id

  enabled_log {
    category = "Connections"
  }

  enabled_log {
    category = "NATPorts"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "public_ip_bastion" {
  name               = "diag-${azurerm_public_ip.bastion.name}"
  storage_account_id = azurerm_storage_account.bootdiag.id
  target_resource_id = azurerm_public_ip.bastion.id

  enabled_log {
    category = "DDoSProtectionNotifications"
  }

  enabled_log {
    category = "DDoSMitigationReports"
  }

  enabled_log {
    category = "DDoSMitigationFlowLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "public_ip_natgateway" {
  name               = "diag-${azurerm_public_ip.natgateway.name}"
  storage_account_id = azurerm_storage_account.bootdiag.id
  target_resource_id = azurerm_public_ip.natgateway.id

  enabled_log {
    category = "DDoSProtectionNotifications"
  }

  enabled_log {
    category = "DDoSMitigationReports"
  }

  enabled_log {
    category = "DDoSMitigationFlowLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  name               = "diag-${azurerm_storage_account.bootdiag.name}"
  storage_account_id = azurerm_storage_account.bootdiag.id
  target_resource_id = "${azurerm_storage_account.bootdiag.id}/blobServices/default"

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "Capacity"
  }

  enabled_metric {
    category = "Transaction"
  }
}

resource "azurerm_monitor_diagnostic_setting" "virtual_network" {
  name               = "diag-${azurerm_virtual_network.cyclecloud.name}"
  storage_account_id = azurerm_storage_account.bootdiag.id
  target_resource_id = azurerm_virtual_network.cyclecloud.id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_storage_account_network_rules" "bootdiag" {
  storage_account_id = azurerm_storage_account.bootdiag.id

  bypass                     = ["AzureServices"]
  default_action             = "Deny"
  ip_rules                   = var.local_ip_address_prefixes
  virtual_network_subnet_ids = [azurerm_subnet.cyclecloud["cyclecloud"].id]
}

