resource "azurerm_key_vault" "cyclecloud" {
  location                    = var.location
  name                        = "kv${random_pet.naming.id}"
  purge_protection_enabled    = false
  resource_group_name         = azurerm_resource_group.cyclecloud.name
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  tenant_id                   = data.azurerm_client_config.current.tenant_id

  enabled_for_deployment  = true
  rbac_authorization_enabled = true
  tags                        = local.common_tags
}

resource "azurerm_key_vault_secret" "password" {
  depends_on = [azurerm_role_assignment.kv_admin]

  key_vault_id = azurerm_key_vault.cyclecloud.id
  name         = "cc-${random_pet.naming.id}-password"
  value        = random_password.vm_password.result
}

resource "azurerm_key_vault_secret" "private_key" {
  depends_on = [azurerm_role_assignment.kv_admin]

  key_vault_id = azurerm_key_vault.cyclecloud.id
  name             = "cc-${random_pet.naming.id}-private-key"
  value_wo         = ephemeral.tls_private_key.cyclecloud_ephemeral.private_key_openssh
  value_wo_version = 1
}

resource "azurerm_key_vault_secret" "public_key" {
  depends_on = [azurerm_role_assignment.kv_admin]

  key_vault_id = azurerm_key_vault.cyclecloud.id
  name             = "cc-${random_pet.naming.id}-public-key"
  value_wo         = ephemeral.tls_public_key.cyclecloud_ephemeral.public_key_openssh
  value_wo_version = 1
}

resource "azurerm_private_dns_zone" "kv" {
  name                = local.dns_names.private_dns_zone_kv
  resource_group_name = azurerm_resource_group.cyclecloud.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = "kv-link"
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  resource_group_name   = azurerm_resource_group.cyclecloud.name
  virtual_network_id    = azurerm_virtual_network.cyclecloud.id
}

resource "azurerm_private_endpoint" "kv" {
  location            = var.location
  name                = "pe-${random_pet.naming.id}-kv"
  resource_group_name = azurerm_resource_group.cyclecloud.name
  subnet_id           = azurerm_subnet.cyclecloud["private_endpoints"].id

  private_service_connection {
    is_manual_connection           = false
    name                           = "kv-connection"
    private_connection_resource_id = azurerm_key_vault.cyclecloud.id
    subresource_names              = ["vault"]
  }

  tags = local.common_tags
}

resource "azurerm_role_assignment" "kv_admin" {
  depends_on = [azurerm_key_vault.cyclecloud]

  principal_id       = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope              = azurerm_key_vault.cyclecloud.id
}

resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  name               = "diag-${azurerm_key_vault.cyclecloud.name}"
  storage_account_id = azurerm_storage_account.bootdiag.id
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