locals {
  configured_current_ip_address = trimspace(var.current_ip_address) != "" ? trimspace(var.current_ip_address) : trimspace(var.CURRENT_IP_ADDRESS)
  effective_ip_allowlist        = distinct(compact(concat(var.local_ip_address_prefixes, local.configured_current_ip_address != "" ? [local.configured_current_ip_address] : [])))

  common_tags = merge(var.tags, {
    component   = "backend-deployment"
    deployed_by = data.azuread_user.current_user.display_name
  })

  private_dns_names = [
    "privatelink.agentsvc.azure-automation.net",
    "privatelink.azure-automation.net",
    "privatelink.blob.core.windows.net",
    "privatelink.azurecr.io",
    "privatelink.ts.eventgrid.azure.net",
    "privatelink.eventgrid.azure.net",
    "privatelink.file.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.dfs.core.windows.net",
    "privatelink.monitor.azure.com",
    "privatelink.mysql.database.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.oms.opinsights.azure.com"
  ]
  ampls_private_dns_zones = [
    "privatelink.monitor.azure.com",
    "privatelink.ods.opinsights.azure.com",
    "privatelink.oms.opinsights.azure.com",
    "privatelink.agentsvc.azure-automation.net",
    "privatelink.blob.core.windows.net"
  ]

  resources_names = ["bastion", "natgateway"]
}