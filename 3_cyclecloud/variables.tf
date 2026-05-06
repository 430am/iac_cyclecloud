variable "admin_username" {
  description = "Admin username for the CycleCloud virtual machine."
  type        = string
  default     = "cyclecloudadmin"
}

variable "ARM_CLIENT_ID" {
  description = "Compatibility input for shared credentials tfvars files."
  type        = string
  default     = ""
}

variable "ARM_CLIENT_SECRET" {
  description = "Compatibility input for shared credentials tfvars files."
  type        = string
  default     = ""
  sensitive   = true
}

variable "ARM_SUBSCRIPTION_ID" {
  description = "Compatibility input for shared credentials tfvars files."
  type        = string
  default     = ""
}

variable "ARM_TENANT_ID" {
  description = "Compatibility input for shared credentials tfvars files."
  type        = string
  default     = ""
}

variable "CURRENT_IP_ADDRESS" {
  description = "Compatibility input for shared credentials tfvars files."
  type        = string
  default     = ""
}

variable "cyclecloud_os_disk_type" {
  description = "Managed disk SKU for the CycleCloud VM OS disk."
  type        = string
  default     = "Premium_LRS"
}

variable "cyclecloud_subnet_name" {
  description = "Name of the subnet in 1_infrastructure used by the CycleCloud VM NIC."
  type        = string
  default     = "CycleCloud"
}

variable "cyclecloud_vm_size" {
  description = "Azure VM size for the CycleCloud server."
  type        = string
  default     = "Standard_D4ads_v6"
}

variable "foundation_state_path" {
  description = "Path to the local Terraform state file from 1_infrastructure."
  type        = string
  default     = "../1_infrastructure/terraform.tfstate"
}

variable "location" {
  description = "Override deployment location. When null, uses the location output from 1_infrastructure."
  type        = string
  default     = null
}

variable "private_endpoints_subnet_name" {
  description = "Name of the subnet in 1_infrastructure where private endpoints are placed."
  type        = string
  default     = "PrivateEndpoints"
}

variable "anf_subnet_name" {
  description = "Name of the existing ANF delegated subnet created in 1_infrastructure."
  type        = string
  default     = "Storage"
}

variable "sig_image_version" {
  description = "Image version from the Shared Image Gallery to use for CycleCloud. Use 'latest' to always consume the newest image."
  type        = string
  default     = "latest"
}

variable "storage_account_tier" {
  description = "Tier for the CycleLocker storage account."
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Replication type for the CycleLocker storage account."
  type        = string
  default     = "LRS"
}

variable "tags" {
  description = "Tags applied to resources in this stage."
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "CycleCloud Infrastructure"
    workload   = "CycleCloud"
  }
}

variable "anf_pool_service_level" {
  description = "Service level for the Azure NetApp pool."
  type        = string
  default     = "Standard"
}

variable "anf_pool_size_tb" {
  description = "Size of the Azure NetApp capacity pool in TB."
  type        = number
  default     = 4
}

variable "anf_sched_quota_gb" {
  description = "Quota in GB for the /sched ANF volume."
  type        = number
  default     = 1024
}

variable "anf_share_quota_gb" {
  description = "Quota in GB for the /share ANF volume."
  type        = number
  default     = 1024
}

