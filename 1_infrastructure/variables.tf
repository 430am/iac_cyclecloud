variable "location" {
    description = "The Azure region where the resources will be deployed."
    type        = string
    default     = "southecentralus"
}

variable "resource_groups" {
    type = list(string)
    default = ["network", "shared", "cyclecloud"]
    description = "The names of the resource groups to create."
}

variable "tags" {
    description = "A map of tags to assign to the resources."
    type        = map(string)
    default     = {
        workload = "CycleCloud"
        project = "CycleCloud Infrastructure"
        managed_by = "terraform"
        deployed_by = data.azuread_user.current_user.display_name
    }
}

variable "vnet_address_space" {
    description = "The address space for the virtual network."
    type        = list(string)
    default     = ["10.100.0.0/16"]
}

variable "subnets" {
    description = "a map of names and address prefixes for the subnets."
    type        = map(object({
        name = string
        address_prefix = string
        private_endpoint_network_policies = string
    }))

    default     = {
        bastion = {
            name = "AzureBastionSubnet"
            address_prefix = "10.100.0.0/26"
            private_endpoint_network_policies = "Disabled"
        },
        anf = {
            name = "0-anf"
            address_prefix = "10.100.0.64/26"
            private_endpoint_network_policies = "Disabled"
        },
        shared = {
            name = "1-shared"
            address_prefix = "10.100.0.128/27"
            private_endpoint_network_policies = "Disabled"
        },
        private_endpoints = {
            name = "2-private-endpoints"
            address_prefix = "10.100.0.160/28"
            private_endpoint_network_policies = "Enabled"
        },
        cyclecloud = {
            name = "3-cyclecloud"
            address_prefix = "10.100.0.172/29"
            private_endpoint_network_policies = "Disabled"
        },
        cluster = {
            name = "4-cluster"
            address_prefix = "10.100.1.0/23"
            private_endpoint_network_policies = "Disabled"
        }
    }
}

variable "admin_username" {
    description = "The admin username for the virtual machines."
    type        = string
    default     = "cyclecloudadmin"
}

variable "vm_skus" {
    description = "The VM SKUs for the virtual machines."
    type        = map(string)
    default     = {
        imaging = "Standard_D2ads_v6"
        cyclecloud = "Standard_D4ads_v6"
    }
}

variable "current_ip_address" {
    description = "The current public IP address of the user running terraform, used for NSG rules to allow access to the bastion host."
    type        = string
    default     = ""
}