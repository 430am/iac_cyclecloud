locals {
  foundation_location                   = try(data.terraform_remote_state.foundation.outputs.resource_group_location, null)
  foundation_key_vault_name             = data.terraform_remote_state.foundation.outputs.key_vault_name
  foundation_log_analytics_workspace_id = data.terraform_remote_state.foundation.outputs.log_analytics_workspace_id
  foundation_public_key_secret_name = try(
    data.terraform_remote_state.foundation.outputs.key_vault_public_key_secret_name,
    "cc-${trimprefix(data.terraform_remote_state.foundation.outputs.key_vault_name, "kv")}-public-key"
  )
  foundation_resource_group_name  = data.terraform_remote_state.foundation.outputs.resource_group_name
  foundation_virtual_network_name = data.terraform_remote_state.foundation.outputs.virtual_network_name
  sig_image_name                  = data.terraform_remote_state.foundation.outputs.sig_image_name
  sig_name                        = data.terraform_remote_state.foundation.outputs.sig_name

  effective_location = var.location != null ? var.location : local.foundation_location

  common_tags = merge(var.tags, {
    component = "cyclecloud-stack"
  })
}
