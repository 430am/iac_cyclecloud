locals {
  common_tags = merge(var.tags, {
    component = "backend-deployment"
  })

  dns_names = {
    private_dns_zone_kv = "privatelink.vaultcore.azure.net"
    private_dns_zone_mysql = "privatelink.mysql.database.azure.com"
    private_dns_zone_eventgrid = "privatelink.eventgrid.azure.net"
    private_dns_zone_eg_topicspace = "privatelink.ts.eventgrid.azure.net"
    private_dns_zone_monitor = "privatelink.monitor.azure.com"
    private_dns_zone_oms = "privatelink.oms.opinsights.azure.com"
    private_dns_zone_ods = "privatelink.ods.opinsights.azure.com"
    private_dns_zone_automation = "privatelink.azure-automation.net"
    private_dns_zone_agentsvc = "privatelink.agentsvc.azure-automation.net"
    private_dns_zone_blob = "privatelink.blob.core.windows.net"
    private_dns_zone_file = "privatelink.file.core.windows.net"
    private_dns_zone_lake = "privatelink.dfs.core.windows.net"
    private_dns_zone_cr = "privatelink.azurecr.io"
  }

  resources_names = ["bastion", "natgateway"]
}