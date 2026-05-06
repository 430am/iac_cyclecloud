data "terraform_remote_state" "foundation" {
  backend = "local"

  config = {
    path = var.foundation_state_path
  }
}

data "azurerm_resource_group" "foundation" {
  name = local.foundation_resource_group_name
}

data "azurerm_key_vault" "foundation" {
  name                = local.foundation_key_vault_name
  resource_group_name = local.foundation_resource_group_name
}

data "azurerm_key_vault_secret" "cyclecloud_public_key" {
  key_vault_id = data.azurerm_key_vault.foundation.id
  name         = local.foundation_public_key_secret_name
}

data "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = local.foundation_resource_group_name
}

data "azurerm_shared_image_gallery" "cyclecloud" {
  name                = local.sig_name
  resource_group_name = local.foundation_resource_group_name
}

data "azurerm_shared_image" "cyclecloud" {
  gallery_name        = data.azurerm_shared_image_gallery.cyclecloud.name
  name                = local.sig_image_name
  resource_group_name = local.foundation_resource_group_name
}

data "azurerm_shared_image_version" "cyclecloud" {
  gallery_name        = data.azurerm_shared_image_gallery.cyclecloud.name
  image_name          = data.azurerm_shared_image.cyclecloud.name
  name                = var.sig_image_version
  resource_group_name = local.foundation_resource_group_name
}

data "azurerm_subnet" "cyclecloud" {
  name                 = var.cyclecloud_subnet_name
  resource_group_name  = local.foundation_resource_group_name
  virtual_network_name = local.foundation_virtual_network_name
}

data "azurerm_subnet" "private_endpoints" {
  name                 = var.private_endpoints_subnet_name
  resource_group_name  = local.foundation_resource_group_name
  virtual_network_name = local.foundation_virtual_network_name
}

data "azurerm_subnet" "anf" {
  name                 = var.anf_subnet_name
  resource_group_name  = local.foundation_resource_group_name
  virtual_network_name = local.foundation_virtual_network_name
}

data "azurerm_virtual_network" "foundation" {
  name                = local.foundation_virtual_network_name
  resource_group_name = local.foundation_resource_group_name
}
