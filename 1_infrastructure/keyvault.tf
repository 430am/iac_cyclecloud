resource "azurerm_key_vault" "cyclecloud" {
  location                   = var.location
  name                       = substr("kv${random_pet.naming.id}", 0, 24)
  purge_protection_enabled   = false
  resource_group_name        = azurerm_resource_group.cyclecloud.name
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  tenant_id                  = data.azurerm_client_config.current.tenant_id

  enabled_for_deployment     = true
  rbac_authorization_enabled = true
  tags                       = local.common_tags

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = local.effective_ip_allowlist
  }
}

resource "azurerm_key_vault_secret" "private_key" {
  depends_on = [azurerm_role_assignment.kv_admin]

  key_vault_id     = azurerm_key_vault.cyclecloud.id
  name             = "cc-${random_pet.naming.id}-private-key"
  value_wo         = ephemeral.tls_private_key.cyclecloud_ephemeral.private_key_openssh
  value_wo_version = 1
}

resource "azurerm_key_vault_secret" "public_key" {
  depends_on = [azurerm_role_assignment.kv_admin]

  key_vault_id     = azurerm_key_vault.cyclecloud.id
  name             = "cc-${random_pet.naming.id}-public-key"
  value_wo         = ephemeral.tls_public_key.cyclecloud_ephemeral.public_key_openssh
  value_wo_version = 1
}

resource "azurerm_role_assignment" "kv_admin" {
  depends_on = [azurerm_key_vault.cyclecloud]

  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.cyclecloud.id
}
