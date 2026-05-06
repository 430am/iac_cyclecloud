resource "azurerm_virtual_machine_extension" "ama" {
  auto_upgrade_minor_version = true
  name                       = "AzureMonitorLinuxAgent"
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  virtual_machine_id         = azurerm_linux_virtual_machine.cyclecloud.id
}

resource "azurerm_monitor_data_collection_rule" "cyclecloud" {
  location            = local.effective_location
  name                = "dcr-cc-${random_pet.naming.id}"
  resource_group_name = data.azurerm_resource_group.foundation.name
  tags                = local.common_tags

  destinations {
    log_analytics {
      name                  = "foundation-law"
      workspace_resource_id = local.foundation_log_analytics_workspace_id
    }
  }

  data_flow {
    destinations = ["foundation-law"]
    streams      = ["Microsoft-Perf", "Microsoft-Syslog"]
  }

  data_sources {
    performance_counter {
      counter_specifiers = [
        "\\Processor Information(_Total)\\% Processor Time",
        "\\Memory\\Available MBytes",
        "\\Logical Disk(_Total)\\% Free Space"
      ]
      name                          = "perf-counters"
      sampling_frequency_in_seconds = 60
      streams                       = ["Microsoft-Perf"]
    }

    syslog {
      facility_names = ["auth", "authpriv", "cron", "daemon", "syslog", "user"]
      log_levels     = ["Critical", "Alert", "Emergency", "Error", "Warning", "Notice", "Info"]
      name           = "syslog-source"
      streams        = ["Microsoft-Syslog"]
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "cyclecloud" {
  data_collection_rule_id = azurerm_monitor_data_collection_rule.cyclecloud.id
  name                    = "dcra-cc-${random_pet.naming.id}"
  target_resource_id      = azurerm_linux_virtual_machine.cyclecloud.id

  depends_on = [azurerm_virtual_machine_extension.ama]
}
