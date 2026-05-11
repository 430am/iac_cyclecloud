# Example Azure service principal credentials for local Terraform use.
# Copy this file to creds.tfvars and replace placeholders with real values.
# Do not commit real credentials to source control.

ARM_SUBSCRIPTION_ID = "00000000-0000-0000-0000-000000000000"
ARM_CLIENT_ID       = "00000000-0000-0000-0000-000000000000"
ARM_CLIENT_SECRET   = "replace-with-client-secret"
ARM_TENANT_ID       = "00000000-0000-0000-0000-000000000000"

# Local IP address to be used in the local_ip_address_prefixes variable for Terraform configuration.
# This should be the public IP address of the user running Terraform, or a CIDR block that includes it, to allow access to the bastion host.
CURRENT_IP_ADDRESS = "0.0.0.0"
