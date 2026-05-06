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

output "key_vault_private_key_secret_name" {
  description = "The secret name storing the CycleCloud private SSH key"
  value       = azurerm_key_vault_secret.private_key.name
}

output "key_vault_public_key_secret_name" {
  description = "The secret name storing the CycleCloud public SSH key"
  value       = azurerm_key_vault_secret.public_key.name
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

output "sig_name" {
  description = "The name of the Shared Image Gallery"
  value       = azurerm_shared_image_gallery.cyclecloud.name
}

output "sig_image_name" {
  description = "The name of the Shared Image definition"
  value       = azurerm_shared_image.cyclecloud.name
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

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.cyclecloud.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.cyclecloud.name
}

output "log_analytics_workspace_workspace_id" {
  description = "The Workspace ID of the Log Analytics Workspace (for agent configuration)"
  value       = azurerm_log_analytics_workspace.cyclecloud.workspace_id
}

output "bastion_host_name" {
  description = "The name of the Bastion host"
  value       = azurerm_bastion_host.cyclecloud.name
}
