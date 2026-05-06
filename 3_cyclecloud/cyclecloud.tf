resource "azurerm_network_interface" "cyclecloud" {
  location            = local.effective_location
  name                = "nic-cc-${random_pet.naming.id}"
  resource_group_name = data.azurerm_resource_group.foundation.name
  tags                = local.common_tags

  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.cyclecloud.id
  }
}

resource "azurerm_linux_virtual_machine" "cyclecloud" {
  admin_username                  = var.admin_username
  disable_password_authentication = true
  location                        = local.effective_location
  name                            = "vm-cc-${random_pet.naming.id}"
  network_interface_ids           = [azurerm_network_interface.cyclecloud.id]
  resource_group_name             = data.azurerm_resource_group.foundation.name
  size                            = var.cyclecloud_vm_size
  source_image_id                 = data.azurerm_shared_image_version.cyclecloud.id
  tags                            = local.common_tags

  admin_ssh_key {
    public_key = trimspace(data.azurerm_key_vault_secret.cyclecloud_public_key.value)
    username   = var.admin_username
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.cyclecloud_os_disk_type
  }

  identity {
    type = "SystemAssigned"
  }
}
