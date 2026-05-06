resource "azurerm_private_endpoint" "cyclelocker_blob" {
  location            = local.effective_location
  name                = "pe-cyclelocker-blob-${random_pet.naming.id}"
  resource_group_name = data.azurerm_resource_group.foundation.name
  subnet_id           = data.azurerm_subnet.private_endpoints.id
  tags                = local.common_tags

  private_service_connection {
    is_manual_connection           = false
    name                           = "psc-cyclelocker-blob-${random_pet.naming.id}"
    private_connection_resource_id = azurerm_storage_account.cyclelocker.id
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "pdzg-cyclelocker-blob-${random_pet.naming.id}"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blob.id]
  }
}
