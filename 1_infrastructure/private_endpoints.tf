resource "azurerm_private_dns_zone" "zones" {
    for_each = toset(local.private_dns_names)
    
    name = each.key
    resource_group_name = azurerm_resource_group.cyclecloud.name
    
}

resource "azurerm_private_dns_zone_virtual_network_link" "zone_links" {
    for_each = toset(local.private_dns_names)
    
    name = "${each.key}-link"
    private_dns_zone_name = each.value
    resource_group_name = azurerm_resource_group.cyclecloud.name
    virtual_network_id = azurerm_virtual_network.cyclecloud.id

    depends_on = [ azurerm_private_dns_zone.zones ]
}

resource "azurerm_monitor_private_link_scope" "ampls" {
    name = "ampls-${random_pet.naming.id}"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    ingestion_access_mode = "PrivateOnly"
}

resource "azurerm_monitor_private_link_scoped_service" "ampls" {
    linked_resource_id = azurerm_log_analytics_workspace.cyclecloud.id
    name = "link-${random_pet.naming.id}"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    scope_name = azurerm_monitor_private_link_scope.ampls.name    
}

## WORKAROUND: wait a few seconds before creating the AMPLS private endpoint to ensure the private link scope is fully provisioned
resource "time_sleep" "ampls_wait" {
    create_duration = "60s"
    depends_on = [ azurerm_monitor_private_link_scope.ampls ]
}

resource "azurerm_private_endpoint" "ampls" {
    name = "pe-ampls-${random_pet.naming.id}"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    location = var.location
    subnet_id = azurerm_subnet.cyclecloud["private_endpoints"].id
    tags = local.common_tags

    private_service_connection {
        name = "psc-${random_pet.naming.id}"
        private_connection_resource_id = azurerm_monitor_private_link_scope.ampls.id
        is_manual_connection = false
        subresource_names = [ "azuremonitor" ]
    }

    private_dns_zone_group {
      name = "pdzg-${random_pet.naming.id}"
      private_dns_zone_ids = [ for zone in local.ampls_private_dns_zones : azurerm_private_dns_zone.zones[zone].id ]
    }

    depends_on = [ time_sleep.ampls_wait ]
}

resource "azurerm_private_endpoint" "kv" {
    name = "pe-kv-${random_pet.naming.id}"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    location = var.location
    subnet_id = azurerm_subnet.cyclecloud["private_endpoints"].id
    tags = local.common_tags

    private_service_connection {
        name = "psc-kv-${random_pet.naming.id}"
        private_connection_resource_id = azurerm_key_vault.cyclecloud.id
        is_manual_connection = false
        subresource_names = [ "vault" ]
    }

    private_dns_zone_group {
      name = "pdzg-kv-${random_pet.naming.id}"
      private_dns_zone_ids = [ azurerm_private_dns_zone.zones["privatelink.vaultcore.azure.net"].id ]
    }
}

resource "azurerm_private_endpoint" "linked_storage" {
    location = var.location
    name = "pe-linked-storage-${random_pet.naming.id}"
    resource_group_name = azurerm_resource_group.cyclecloud.name
    subnet_id = azurerm_subnet.cyclecloud["private_endpoints"].id
    tags = local.common_tags

    private_service_connection {
        is_manual_connection = false
        name = "psc-linked-storage-${random_pet.naming.id}"
        private_connection_resource_id = azurerm_storage_account.monitoring.id
        subresource_names = [ "blob" ]
    }
    
    private_dns_zone_group {
      name = "pdzg-stor-${random_pet.naming.id}"
      private_dns_zone_ids = [ azurerm_private_dns_zone.zones["privatelink.blob.core.windows.net"].id ]
    }
}