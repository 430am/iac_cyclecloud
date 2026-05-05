variable "admin_username" {
  description = "The admin username for the virtual machines."
  type        = string
  default     = "cyclecloudadmin"
}

variable "current_ip_address" {
  description = "The current public IP address of the user running terraform, used for NSG rules to allow access to the bastion host."
  type        = string
  default     = ""
}

variable "local_ip_address_prefixes" {
  description = "A list of CIDR blocks representing the local IP address ranges that should be allowed to access the bastion host."
  type        = list(string)
  default     = []
}

variable "location" {
  description = "The Azure region where the resources will be deployed."
  type        = string
  default     = "southcentralus"
}

variable "subnets" {
  description = "A map of names and address prefixes for the subnets."
  type = map(object({
    address_prefix                    = string
    name                              = string
    private_endpoint_network_policies = string
  }))
  default = {
    anf = {
      address_prefix                    = "10.100.0.64/26"
      name                              = "0-anf"
      private_endpoint_network_policies = "Disabled"
    }
    bastion = {
      address_prefix                    = "10.100.0.0/26"
      name                              = "AzureBastionSubnet"
      private_endpoint_network_policies = "Disabled"
    }
    cluster = {
      address_prefix                    = "10.100.2.0/23"
      name                              = "4-cluster"
      private_endpoint_network_policies = "Disabled"
    }
    cyclecloud = {
      address_prefix                    = "10.100.0.176/29"
      name                              = "3-cyclecloud"
      private_endpoint_network_policies = "Disabled"
    }
    private_endpoints = {
      address_prefix                    = "10.100.0.160/28"
      name                              = "2-private-endpoints"
      private_endpoint_network_policies = "Enabled"
    }
    shared = {
      address_prefix                    = "10.100.0.128/27"
      name                              = "1-shared"
      private_endpoint_network_policies = "Disabled"
    }
  }
}

variable "tags" {
  description = "A map of tags to assign to the resources."
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "CycleCloud Infrastructure"
    workload   = "CycleCloud"
  }
}

variable "vm_skus" {
  description = "The VM SKUs for the virtual machines."
  type        = map(string)
  default = {
    cyclecloud = "Standard_D4ads_v6"
    imaging    = "Standard_D2ads_v6"
  }
}

variable "vnet_address_space" {
  description = "The address space for the virtual network."
  type        = list(string)
  default     = ["10.100.0.0/16"]
}