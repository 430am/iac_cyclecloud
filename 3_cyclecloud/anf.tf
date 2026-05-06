resource "azurerm_netapp_account" "cyclecloud" {
  location            = local.effective_location
  name                = "anf-${random_pet.naming.id}"
  resource_group_name = data.azurerm_resource_group.foundation.name
  tags                = local.common_tags
}

resource "azurerm_netapp_pool" "cyclecloud" {
  account_name        = azurerm_netapp_account.cyclecloud.name
  location            = local.effective_location
  name                = "pool-${random_pet.naming.id}"
  resource_group_name = data.azurerm_resource_group.foundation.name
  service_level       = var.anf_pool_service_level
  size_in_tb          = var.anf_pool_size_tb
  tags                = local.common_tags
}

resource "azurerm_netapp_volume" "sched" {
  account_name        = azurerm_netapp_account.cyclecloud.name
  location            = local.effective_location
  name                = "sched"
  pool_name           = azurerm_netapp_pool.cyclecloud.name
  protocols           = ["NFSv3"]
  resource_group_name = data.azurerm_resource_group.foundation.name
  security_style      = "unix"
  service_level       = var.anf_pool_service_level
  storage_quota_in_gb = var.anf_sched_quota_gb
  subnet_id           = data.azurerm_subnet.anf.id
  tags                = local.common_tags
  volume_path         = "sched"
}

resource "azurerm_netapp_volume" "share" {
  account_name        = azurerm_netapp_account.cyclecloud.name
  location            = local.effective_location
  name                = "share"
  pool_name           = azurerm_netapp_pool.cyclecloud.name
  protocols           = ["NFSv3"]
  resource_group_name = data.azurerm_resource_group.foundation.name
  security_style      = "unix"
  service_level       = var.anf_pool_service_level
  storage_quota_in_gb = var.anf_share_quota_gb
  subnet_id           = data.azurerm_subnet.anf.id
  tags                = local.common_tags
  volume_path         = "share"
}
