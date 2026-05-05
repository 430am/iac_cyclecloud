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

  enabled_log {
    category = "NatGatewayFlowlogsV1"
  }

    enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_monitor_diagnostic_setting" "pe_kv" {
    name = "diag-${azurerm_private_endpoint.kv.name}"
    target_resource_id = azurerm_private_endpoint.kv.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.cyclecloud.id
    log_analytics_destination_type = "Dedicated"
    
    enabled_metric {
      category = "AllMetrics"
    }
}

resource "azurerm_monitor_diagnostic_setting" "pe_monitoring" {
    name = "diag-${azurerm_private_endpoint.monitoring.name}"
    target_resource_id = azurerm_private_endpoint.monitoring.id
    log_analytics_workspace_id = azurerm_log_analytics_workspace.cyclecloud.id
    log_analytics_destination_type = "Dedicated"
    
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

resource "azurerm_private_dns_zone" "monitoring" {
    for_each = toset([
        "monitor.azure.com",
        "ods.opinsights.azure.com",
        "oms.opinsights.azure.com",
        "agentservice.azure.com",
        "blob.core.windows.net"
    ])
    
    name = "privatelink.${each.key}"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    tags = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "monitoring" {
    for_each = toset([
        "monitor.azure.com",
        "ods.opinsights.azure.com",
        "oms.opinsights.azure.com",
        "agentservice.azure.com",
        "blob.core.windows.net"
    ])
    
    name = "${azurerm_private_dns_zone.monitoring[each.key].name}-link"
    private_dns_zone_name = azurerm_private_dns_zone.monitoring[each.key].name
    resource_group_name = azurerm_resource_group.cyclecloud.name
    virtual_network_id = azurerm_virtual_network.cyclecloud.id
}

resource "azurerm_monitor_private_link_scope" "monitoring" {
    name = "${random_pet.naming.id}-scope"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    
}

resource "azurerm_private_endpoint" "monitoring" {
    location = var.location
    name = "pe-${random_pet.naming.id}-monitoring"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    subnet_id = azurerm_subnet.cyclecloud["private_endpoints"].id
    tags = local.common_tags
    
    private_service_connection {
        is_manual_connection = false
        name = "psc-for-monitoring"
        private_connection_resource_id = azurerm_monitor_private_link_scope.monitoring.id
        subresource_names = ["azuremonitor"]
    }

    private_dns_zone_group {
      name = "dns-${random_pet.naming.id}-group"
      private_dns_zone_ids = [
        azurerm_private_dns_zone.monitoring["monitor.azure.com"].id,
        azurerm_private_dns_zone.monitoring["ods.opinsights.azure.com"].id,
        azurerm_private_dns_zone.monitoring["oms.opinsights.azure.com"].id,
        azurerm_private_dns_zone.monitoring["agentservice.azure.com"].id,
        azurerm_private_dns_zone.monitoring["blob.core.windows.net"].id
      ]
    }
    
}

resource "azurerm_monitor_private_link_scoped_service" "monitoring" {
    linked_resource_id = azurerm_monitor_private_link_scope.monitoring.id
    name = "scoped-service-${random_pet.naming.id}"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    scope_name = azurerm_monitor_private_link_scope.monitoring.name
    
}