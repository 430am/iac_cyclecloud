# Example variables for the Packer image build.
# Copy this file to creds.pkrvars.hcl and replace placeholders with real values.
# Do not commit real credentials to source control.

subscription_id = "00000000-0000-0000-0000-000000000000"
location        = "southcentralus"

# Shared Image Gallery values from 1_infrastructure.
sig_resource_group_name = "rg-<random-suffix>"
sig_name                = "sig<random-suffix>"
sig_image_name          = "image-<random-suffix>"
# Optional: set explicitly, otherwise the template auto-generates a unique timestamp version.
# image_version           = "20260506.1405.12"
key_vault_name                = "kv<random-suffix>"
key_vault_password_secret_name = "cc-<random-suffix>-password"
cyclecloud_tenant_id          = "00000000-0000-0000-0000-000000000000"
cyclecloud_account_name       = "default"

# Build settings.
build_vm_size            = "Standard_D4ads_v6"
ssh_username             = "azureuser"
replication_regions      = ["southcentralus"]
sig_storage_account_type = "Standard_LRS"

# Use your existing az login session by default.
use_azure_cli_auth = true

# Optional service principal authentication instead of az login.
# tenant_id     = "00000000-0000-0000-0000-000000000000"
# client_id     = "00000000-0000-0000-0000-000000000000"
# client_secret = "replace-with-client-secret"
