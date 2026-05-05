output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.cyclecloud.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.cyclecloud.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.cyclecloud.vault_uri
}

output "resource_group_id" {
  description = "The ID of the Resource Group"
  value       = azurerm_resource_group.cyclecloud.id
}

output "resource_group_location" {
  description = "The location of the Resource Group"
  value       = azurerm_resource_group.cyclecloud.location
}

output "resource_group_name" {
  description = "The name of the Resource Group"
  value       = azurerm_resource_group.cyclecloud.name
}

output "storage_account_id" {
  description = "The ID of the Storage Account"
  value       = azurerm_storage_account.bootdiag.id
}

output "storage_account_name" {
  description = "The name of the Storage Account"
  value       = azurerm_storage_account.bootdiag.name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint of the Storage Account"
  value       = azurerm_storage_account.bootdiag.primary_blob_endpoint
}

output "virtual_network_address_space" {
  description = "The address space of the Virtual Network"
  value       = azurerm_virtual_network.cyclecloud.address_space
}

output "virtual_network_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.cyclecloud.id
}

output "virtual_network_name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.cyclecloud.name
}
