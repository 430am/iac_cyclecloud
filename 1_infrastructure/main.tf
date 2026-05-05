data "azuread_user" "current_user" {
  object_id = data.azurerm_client_config.current.object_id
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "random_password" "vm_password" {
  length  = 16
  special = true
}

resource "random_pet" "naming" {
  length    = 2
  separator = ""
}

resource "azurerm_resource_group" "cyclecloud" {
  location = var.location
  name     = "rg-${random_pet.naming.id}"
  tags     = local.common_tags
}

resource "azurerm_role_assignment" "cyclecloud" {
  depends_on = [azurerm_role_definition.cyclecloud]

  principal_id       = azurerm_user_assigned_identity.cyclecloud.principal_id
  role_definition_id = azurerm_role_definition.cyclecloud.role_definition_resource_id
  scope              = data.azurerm_subscription.current.id
}

resource "azurerm_role_definition" "cyclecloud" {
  description = "Custom role to provide least privilege capabilities to deliver CycleCloud services in Azure"
  name        = "CycleCloud Orchestrator Role"
  scope       = data.azurerm_subscription.current.id

  assignable_scopes = [data.azurerm_subscription.current.id]

  permissions {
    actions = [
      "Microsoft.Authorization/*/read",
      "Microsoft.Authorization/roleAssignments/*",
      "Microsoft.Authorization/roleDefinitions/*",
      "Microsoft.Commerce/RateCard/read",
      "Microsoft.Compute/*/read",
      "Microsoft.Compute/availabilitySets/*",
      "Microsoft.Compute/disks/*",
      "Microsoft.Compute/images/read",
      "Microsoft.Compute/locations/usages/read",
      "Microsoft.Compute/register/action",
      "Microsoft.Compute/skus/read",
      "Microsoft.Compute/virtualMachines/*",
      "Microsoft.Compute/virtualMachineScaleSets/*",
      "Microsoft.Compute/virtualMachineScaleSets/virtualMachines/*",
      "Microsoft.ManagedIdentity/userAssignedIdentities/*/assign/action",
      "Microsoft.ManagedIdentity/userAssignedIdentities/*/read",
      "Microsoft.MarketplaceOrdering/offertypes/publishers/offers/plans/agreements/read",
      "Microsoft.MarketplaceOrdering/offertypes/publishers/offers/plans/agreements/write",
      "Microsoft.Network/*/read",
      "Microsoft.Network/locations/*/read",
      "Microsoft.Network/networkInterfaces/delete",
      "Microsoft.Network/networkInterfaces/join/action",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/write",
      "Microsoft.Network/networkSecurityGroups/delete",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/networkSecurityGroups/write",
      "Microsoft.Network/publicIPAddresses/delete",
      "Microsoft.Network/publicIPAddresses/join/action",
      "Microsoft.Network/publicIPAddresses/read",
      "Microsoft.Network/publicIPAddresses/write",
      "Microsoft.Network/register/action",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Resources/deployments/read",
      "Microsoft.Resources/subscriptions/operationresults/read",
      "Microsoft.Resources/subscriptions/resourceGroups/delete",
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Resources/subscriptions/resourceGroups/resources/read",
      "Microsoft.Resources/subscriptions/resourceGroups/write",
      "Microsoft.Storage/*/read",
      "Microsoft.Storage/checknameavailability/read",
      "Microsoft.Storage/register/action",
      "Microsoft.Storage/storageAccounts/blobServices/containers/delete",
      "Microsoft.Storage/storageAccounts/blobServices/containers/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/write",
      "Microsoft.Storage/storageAccounts/blobServices/generateUserDelegationKey/action",
      "Microsoft.Storage/storageAccounts/listKeys/action",
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Storage/storageAccounts/write",
    ]
    data_actions = [
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/add/action",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/delete",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/move/action",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read",
      "Microsoft.Storage/storageAccounts/blobServices/containers/blobs/write",
    ]
    not_actions      = []
    not_data_actions = []
  }
}

resource "azurerm_user_assigned_identity" "cyclecloud" {
  location            = var.location
  name                = "uaid-${random_pet.naming.id}-cyclecloud"
  resource_group_name = azurerm_resource_group.cyclecloud.name
  tags                = local.common_tags
}

resource "tls_private_key" "cyclecloud" {
  algorithm = "ED25519"
}

data "tls_public_key" "cyclecloud" {
  private_key_openssh = tls_private_key.cyclecloud.private_key_openssh
}

ephemeral "tls_private_key" "cyclecloud_ephemeral" {
  algorithm = "ED25519"
}

ephemeral "tls_public_key" "cyclecloud_ephemeral" {
  private_key_openssh = ephemeral.tls_private_key.cyclecloud_ephemeral.private_key_openssh
}