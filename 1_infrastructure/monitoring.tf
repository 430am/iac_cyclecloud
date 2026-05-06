resource "azurerm_log_analytics_workspace" "cyclecloud" {
    location = var.location
    name = "${random_pet.naming.id}logs"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    sku = "PerGB2018"
    retention_in_days = 30
    tags = local.common_tags
}

resource "azurerm_monitor_diagnostic_setting" "bastion_host" {
  name               = "diag-${azurerm_bastion_host.cyclecloud.name}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
  target_resource_id = azurerm_bastion_host.cyclecloud.id

  enabled_log {
    category = "BastionAuditLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name               = "diag-${azurerm_key_vault.cyclecloud.name}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
  target_resource_id = azurerm_key_vault.cyclecloud.id

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
  name               = "diag-${azurerm_nat_gateway.cyclecloud.name}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
  target_resource_id = azurerm_nat_gateway.cyclecloud.id

    enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "public_ip_bastion" {
  name               = "diag-${azurerm_public_ip.bastion.name}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
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
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
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

resource "azurerm_monitor_diagnostic_setting" "virtual_network" {
  name               = "diag-${azurerm_virtual_network.cyclecloud.name}"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cyclecloud.id
  log_analytics_destination_type = "Dedicated"
  target_resource_id = azurerm_virtual_network.cyclecloud.id

  enabled_log {
    category = "VMProtectionAlerts"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}