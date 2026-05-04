resource "azurerm_storage_account" "bootdiag" {
    account_replication_type = "LRS"
    account_tier = "StorageV2"
    location = var.location
    name = "bootdiag${random_pet.naming.id}"
    resource_group_name = azurerm_resource_group.cyclecloud[1].name
    tags = local.common_tags
    default_to_oauth_authentication = true
    https_traffic_only_enabled = true
    allow_nested_items_to_be_public = false
    min_tls_version = "TLS1_2"
}
