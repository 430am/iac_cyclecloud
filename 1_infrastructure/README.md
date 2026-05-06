# 1_infrastructure

Terraform configuration that deploys the complete Azure foundation required to run CycleCloud.
All resource names include a randomly generated two-word suffix so multiple deployments can coexist
in the same subscription without name collisions.

## Architecture

```
Subscription
└── Resource Group  (rg-<suffix>)
    ├── Virtual Network  (vnet-<suffix>)
    │   ├── AzureBastionSubnet          10.100.2.0/26
    │   ├── Storage (ANF)               10.100.2.64/26
    │   ├── PrivateEndpoints            10.100.2.128/27
    │   ├── CycleCloud                  10.100.2.192/27
    │   ├── SharedServices              10.100.2.224/27
    │   └── Cluster                     10.100.0.0/23
    ├── Azure Bastion  (Standard SKU, tunneling enabled)
    ├── NAT Gateway  (attached to cluster, cyclecloud, and shared subnets)
    ├── Key Vault  (RBAC-enabled, private endpoint)
    ├── Shared Image Gallery + Image Definition  (Ubuntu 24.04 DSVM)
    ├── Log Analytics Workspace  (system-assigned identity)
    ├── Azure Monitor Data Collection Endpoint  (Linux)
    ├── Storage Account  (linked to Log Analytics for ingestion)
    ├── Azure Monitor Private Link Scope  (private endpoint)
    ├── User-Assigned Managed Identity
    └── Custom RBAC Role  (CycleCloud Orchestrator Role)
```

## Resources

| Resource | Description |
|---|---|
| `azurerm_resource_group` | Single resource group for all components |
| `azurerm_virtual_network` | VNet with configurable address space (default `10.100.0.0/16`) |
| `azurerm_subnet` | Six subnets serving Bastion, ANF (delegated to `Microsoft.Netapp/volumes`), shared services, private endpoints, CycleCloud, and cluster nodes |
| `azurerm_bastion_host` | Standard-SKU Bastion with copy-paste and native client tunnelling |
| `azurerm_nat_gateway` | Outbound internet connectivity for cluster, cyclecloud, and shared subnets |
| `azurerm_key_vault` | Stores the VM password, SSH private key, and SSH public key generated at apply time |
| `azurerm_shared_image_gallery` | Hosts custom CycleCloud image versions built by `2_packer_image` |
| `azurerm_shared_image` | Image definition for `microsoft-dsvm / ubuntu-hpc / 2404` (Gen V2, NVMe-enabled) |
| `azurerm_log_analytics_workspace` | Centralised log sink (PerGB2018, 30-day retention, system-assigned identity) |
| `azurerm_log_analytics_linked_storage_account` | Links the monitoring storage account to the workspace for ingestion |
| `azurerm_monitor_data_collection_endpoint` | Linux DCE used by data collection rules targeting the workspace |
| `azurerm_monitor_private_link_scope` | Private connectivity to Azure Monitor services |
| `azurerm_storage_account` (`monitoring`) | Customer-managed storage backing Log Analytics ingestion (Standard LRS, key access disabled, Deny default + AzureServices/Logging/Metrics bypass) |
| `azurerm_role_assignment` (`monitoring`) | Grants the workspace identity `Storage Table Data Contributor` and `Storage Blob Data Contributor` on the monitoring storage account |
| `azurerm_private_endpoint` (`kv`, `ampls`, `linked_storage`) | Private endpoints for Key Vault, Azure Monitor Private Link Scope, and the monitoring storage account (blob) |
| `azurerm_user_assigned_identity` | Managed identity used by the CycleCloud VM |
| `azurerm_role_definition` | Least-privilege custom role granting CycleCloud the permissions it needs |

### Key Vault secrets stored at apply time

| Secret name | Contents |
|---|---|
| `cc-<suffix>-password` | Random 16-char VM admin password |
| `cc-<suffix>-private-key` | Ephemeral ED25519 SSH private key |
| `cc-<suffix>-public-key` | Corresponding SSH public key |

### Diagnostic settings forwarded to Log Analytics

- Azure Bastion (audit logs + metrics)
- Key Vault (audit events + policy evaluation + metrics)
- NAT Gateway (metrics)
- Bastion public IP (DDoS notifications, reports, flow logs + metrics)
- NAT Gateway public IP (DDoS notifications, reports, flow logs + metrics)
- Virtual Network (VM protection alerts + metrics)

## Prerequisites

- Terraform >= 1.0
- Azure CLI (`az`) configured, **or** a service principal with the values below
- The deploying identity must have permission to create resources and assign RBAC roles at subscription scope

## Variables

| Variable | Default | Description |
|---|---|---|
| `location` | `southcentralus` | Azure region for all resources |
| `admin_username` | `cyclecloudadmin` | Admin username for VMs |
| `vnet_address_space` | `["10.100.0.0/16"]` | VNet CIDR block |
| `subnets` | *(see variables.tf)* | Map of subnet names and address prefixes |
| `vm_skus` | `Standard_D4ads_v6` / `Standard_D2ads_v6` | VM sizes for CycleCloud and imaging |
| `tags` | *(see variables.tf)* | Tags applied to all resources |
| `current_ip_address` / `CURRENT_IP_ADDRESS` | `""` | Your public IP (CIDR) for allowlisting |

## Outputs

| Output | Description |
|---|---|
| `resource_group_name` | Resource group name (used by Packer and downstream stages) |
| `sig_name` | Shared Image Gallery name |
| `sig_image_name` | Shared Image definition name |
| `resource_group_location` | Deployment region |
| `key_vault_name` | Key Vault name |
| `key_vault_uri` | Key Vault URI |
| `key_vault_public_key_secret_name` | Key Vault secret name containing the CycleCloud SSH public key |
| `key_vault_private_key_secret_name` | Key Vault secret name containing the CycleCloud SSH private key |
| `virtual_network_name` | VNet name |
| `log_analytics_workspace_name` | Log Analytics workspace name |

## Deployment

### 1. Set up credentials

```bash
cp environments/example.tfvars environments/creds.tfvars
# Fill in ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
# Set CURRENT_IP_ADDRESS to your public IP in CIDR notation (e.g. 203.0.113.10/32)
```

Export as environment variables before running Terraform:

```bash
export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_TENANT_ID="<tenant-id>"
```

### 2. Deploy

```bash
terraform init
terraform plan -var-file=environments/creds.tfvars
terraform apply -var-file=environments/creds.tfvars
```

### 3. Note the SIG outputs

After `apply` completes, retrieve the values needed by the Packer image build:

```bash
RG_NAME=$(terraform output -raw resource_group_name)
SIG_NAME=$(terraform output -raw sig_name)
SIG_IMAGE_NAME=$(terraform output -raw sig_image_name)
echo "resource_group: $RG_NAME"
echo "sig_name:        $SIG_NAME"
echo "sig_image_name:  $SIG_IMAGE_NAME"
```

## Files

| File | Purpose |
|---|---|
| `providers.tf` | Provider requirements and configuration |
| `main.tf` | Resource group, managed identity, custom role, SSH key generation |
| `network.tf` | VNet, subnets, Bastion, NAT Gateway, public IPs |
| `keyvault.tf` | Key Vault, secrets, private DNS zone, private endpoint |
| `imagegallery.tf` | Shared Image Gallery and image definition |
| `monitoring.tf` | Log Analytics, diagnostic settings, Monitor Private Link Scope |
| `variables.tf` | Input variable definitions |
| `locals.tf` | Computed locals (tags, DNS zone names, IP allowlist) |
| `outputs.tf` | Exported values for downstream use |
| `environments/example.tfvars` | Template credential file |
