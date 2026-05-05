resource "azurerm_bastion_host" "cyclecloud" {
  location            = var.location
  name                = "bastion-${random_pet.naming.id}"
  resource_group_name = azurerm_resource_group.cyclecloud.name
  sku                 = "Standard"

  copy_paste_enabled = true
  tunneling_enabled  = true

  ip_configuration {
    name                 = "bastion-ip-config"
    public_ip_address_id = azurerm_public_ip.bastion.id
    subnet_id            = azurerm_subnet.cyclecloud["bastion"].id
  }
}

resource "azurerm_nat_gateway" "cyclecloud" {
  location            = var.location
  name                = "natgateway-${random_pet.naming.id}"
  resource_group_name = azurerm_resource_group.cyclecloud.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "cyclecloud" {
  nat_gateway_id       = azurerm_nat_gateway.cyclecloud.id
  public_ip_address_id = azurerm_public_ip.natgateway.id
}

resource "azurerm_public_ip" "bastion" {
  allocation_method   = "Static"
  location            = var.location
  name                = "pip-${random_pet.naming.id}-bastion"
  resource_group_name = azurerm_resource_group.cyclecloud.name
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_public_ip" "natgateway" {
  allocation_method   = "Static"
  location            = var.location
  name                = "pip-${random_pet.naming.id}-natgateway"
  resource_group_name = azurerm_resource_group.cyclecloud.name
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_subnet" "cyclecloud" {
  for_each = var.subnets

  address_prefixes                  = [each.value.address_prefix]
  name                              = each.value.name
  private_endpoint_network_policies = each.value.private_endpoint_network_policies
  resource_group_name               = azurerm_resource_group.cyclecloud.name
  virtual_network_name              = azurerm_virtual_network.cyclecloud.name
}

resource "azurerm_subnet_nat_gateway_association" "cyclecloud" {
  nat_gateway_id = azurerm_nat_gateway.cyclecloud.id
  subnet_id      = azurerm_subnet.cyclecloud["cluster"].id
}

resource "azurerm_virtual_network" "cyclecloud" {
  address_space       = var.vnet_address_space
  location            = var.location
  name                = "vnet-${random_pet.naming.id}"
  resource_group_name = azurerm_resource_group.cyclecloud.name
  tags                = local.common_tags
}
