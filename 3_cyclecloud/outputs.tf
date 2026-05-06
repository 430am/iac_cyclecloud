output "anf_share_mount_ip_addresses" {
  description = "Mount target IP addresses for the /share Azure NetApp volume."
  value       = azurerm_netapp_volume.share.mount_ip_addresses
}

output "anf_sched_mount_ip_addresses" {
  description = "Mount target IP addresses for the /sched Azure NetApp volume."
  value       = azurerm_netapp_volume.sched.mount_ip_addresses
}

output "cyclecloud_private_ip" {
  description = "Private IP assigned to the CycleCloud server NIC."
  value       = azurerm_network_interface.cyclecloud.private_ip_address
}

output "cyclecloud_public_key_secret_name" {
  description = "Key Vault secret name used for the CycleCloud VM SSH public key."
  value       = local.foundation_public_key_secret_name
}

output "cyclecloud_storage_account_name" {
  description = "Storage account used for CycleLocker blobs."
  value       = azurerm_storage_account.cyclelocker.name
}

output "cyclecloud_vm_dcr_association_id" {
  description = "Data Collection Rule association ID linking the CycleCloud VM to Azure Monitor logs ingestion."
  value       = azurerm_monitor_data_collection_rule_association.cyclecloud.id
}

output "cyclecloud_vm_dcr_id" {
  description = "Data Collection Rule ID used by the CycleCloud VM for AMA log collection."
  value       = azurerm_monitor_data_collection_rule.cyclecloud.id
}

output "cyclecloud_vm_id" {
  description = "Resource ID of the CycleCloud virtual machine."
  value       = azurerm_linux_virtual_machine.cyclecloud.id
}
