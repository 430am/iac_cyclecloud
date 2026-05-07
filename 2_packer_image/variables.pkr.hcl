variable "subscription_id" {
  description = "Azure subscription ID used by Packer during the image build."
  type        = string
}

variable "tenant_id" {
  description = "Optional tenant ID for service principal authentication. Leave empty when using Azure CLI auth."
  type        = string
  default     = ""
}

variable "client_id" {
  description = "Optional client ID for service principal authentication. Leave empty when using Azure CLI auth."
  type        = string
  default     = ""
}

variable "client_secret" {
  description = "Optional client secret for service principal authentication. Leave empty when using Azure CLI auth."
  type        = string
  default     = ""
  sensitive   = true
}

variable "use_azure_cli_auth" {
  description = "Use the local az login session for authenticating Packer to Azure."
  type        = bool
  default     = true
}

variable "location" {
  description = "Azure region where the temporary image build VM runs."
  type        = string
  default     = "southcentralus"
}

variable "build_vm_size" {
  description = "Size of the temporary VM used by Packer to build the image."
  type        = string
  default     = "Standard_D4ads_v6"
}

variable "ssh_username" {
  description = "SSH username used by Packer to connect to the temporary build VM."
  type        = string
  default     = "azureuser"
}

variable "image_version" {
  description = "Optional explicit SIG image version (major.minor.patch). Leave empty to auto-generate per build."
  type        = string
  default     = ""
}

variable "sig_resource_group_name" {
  description = "Resource group containing the Shared Image Gallery."
  type        = string
}

variable "sig_name" {
  description = "Name of the Shared Image Gallery created by Terraform."
  type        = string
}

variable "sig_image_name" {
  description = "Name of the Shared Image definition created by Terraform."
  type        = string
}

variable "replication_regions" {
  description = "Azure regions that should receive replicated copies of the published image version."
  type        = list(string)
  default     = ["southcentralus"]
}

variable "sig_storage_account_type" {
  description = "Storage type for the SIG image version artifacts."
  type        = string
  default     = "Standard_LRS"
}

variable "key_vault_name" {
  description = "Name of the Key Vault created by 1_infrastructure."
  type        = string
  default     = ""
}

variable "key_vault_password_secret_name" {
  description = "Name of the Key Vault secret that stores the CycleCloud admin password (CCPASSWORD)."
  type        = string
  default     = ""
}

variable "cyclecloud_tenant_id" {
  description = "Tenant ID to write into the CycleCloud Azure account file. If unset, tenant_id is used."
  type        = string
  default     = ""
}

variable "cyclecloud_account_name" {
  description = "Name for the CycleCloud Azure account created during image build."
  type        = string
  default     = "default"
}