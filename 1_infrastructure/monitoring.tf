resource "azurerm_log_analytics_workspace" "cyclecloud" {
  location            = var.location
  name                = "${random_pet.naming.id}logs"
  resource_group_name = azurerm_resource_group.cyclecloud.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.common_tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_log_analytics_linked_storage_account" "monitoring" {
  data_source_type    = "Ingestion"
  resource_group_name = azurerm_resource_group.cyclecloud.name
  storage_account_ids = [azurerm_storage_account.monitoring.id]
  workspace_id        = azurerm_log_analytics_workspace.cyclecloud.id

  depends_on = [ azurerm_role_assignment.monitoring, time_sleep.linked_storage_wait ]
}

resource "time_sleep" "linked_storage_wait" {
    create_duration = "60s"
    depends_on = [ azurerm_role_assignment.monitoring ]
}

resource "azurerm_monitor_data_collection_endpoint" "cyclecloud" {
  name                = "dce-${random_pet.naming.id}"
  resource_group_name = azurerm_resource_group.cyclecloud.name
  location            = var.location
  kind                = "Linux"
  tags                = local.common_tags
}

resource "azurerm_monitor_diagnostic_setting" "bastion_host" {
  name                           = "diag-${azurerm_bastion_host.cyclecloud.name}"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
  target_resource_id             = azurerm_bastion_host.cyclecloud.id

  enabled_log {
    category = "BastionAuditLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name                           = "diag-${azurerm_key_vault.cyclecloud.name}"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
  target_resource_id             = azurerm_key_vault.cyclecloud.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nat_gateway" {
  name                           = "diag-${azurerm_nat_gateway.cyclecloud.name}"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
  target_resource_id             = azurerm_nat_gateway.cyclecloud.id

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "public_ip_bastion" {
  name                           = "diag-${azurerm_public_ip.bastion.name}"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
  target_resource_id             = azurerm_public_ip.bastion.id

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
  name                           = "diag-${azurerm_public_ip.natgateway.name}"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
  target_resource_id             = azurerm_public_ip.natgateway.id

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

resource "azurerm_monitor_diagnostic_setting" "virtual_network" {
  name                           = "diag-${azurerm_virtual_network.cyclecloud.name}"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
  target_resource_id             = azurerm_virtual_network.cyclecloud.id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_role_assignment" "monitoring" {
  for_each = toset(["Storage Table Data Contributor", "Storage Blob Data Contributor"])

  principal_id         = azurerm_log_analytics_workspace.cyclecloud.identity[0].principal_id
  role_definition_name = each.key
  scope                = azurerm_storage_account.monitoring.id

  depends_on = [azurerm_log_analytics_workspace.cyclecloud, azurerm_storage_account.monitoring]
}

resource "azurerm_storage_account" "monitoring" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = var.location
  name                     = substr("mon${random_pet.naming.id}", 0, 24)
  resource_group_name      = azurerm_resource_group.cyclecloud.name
  tags                     = local.common_tags
  shared_access_key_enabled = false
  allow_nested_items_to_be_public = false
  public_network_access_enabled = true

  network_rules {
    default_action = "Deny"
    bypass = [ "AzureServices", "Logging", "Metrics" ]
  }
}