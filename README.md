# IAC CycleCloud

Infrastructure-as-Code (IaC) for deploying Azure CycleCloud infrastructure using Terraform.

## Overview

This repository provides Terraform configurations to deploy and manage Azure CycleCloud infrastructure with enterprise-grade security and compliance features.

## Architecture

### Components

**1_infrastructure/** - Core Azure infrastructure deployment including:
- **Resource Groups** - Organized resource grouping for network, shared services, and CycleCloud
- **Virtual Networking** - VNet with multiple subnets for bastion, ANF, shared services, and private endpoints
- **Security** - Custom role definitions providing least-privilege access to CycleCloud services
- **Identity** - User-assigned managed identities for secure service authentication
- **DNS** - Private DNS zones for secure internal communication
- **Storage** - Azure Storage accounts with encrypted blob services
- **Monitoring** - Log Analytics workspace with diagnostic settings and private endpoints for secure monitoring

## Prerequisites

- Terraform >= 1.0
- Azure CLI configured with appropriate credentials
- Azure subscription with sufficient permissions

## Providers

- `azurerm` - Azure Resource Manager (v4.x)
- `azuread` - Azure Active Directory (v3.x)
- `random` - Random resource naming (v3.x)
- `tls` - TLS certificate generation (v4.x)

## Deployment

### Deploy infrastructure
```bash
cd 1_infrastructure/
terraform init
terraform plan
terraform apply
```

### Environment credentials (tfvars)

An example credentials file is available at `1_infrastructure/environments/example.tfvars`.

To use it locally:

```bash
cp 1_infrastructure/environments/example.tfvars 1_infrastructure/environments/creds.tfvars
# Edit creds.tfvars and replace placeholders with your values.
```

Export the values from `creds.tfvars` before running Terraform:

```bash
export ARM_SUBSCRIPTION_ID="<your-subscription-id>"
export ARM_CLIENT_ID="<your-client-id>"
export ARM_CLIENT_SECRET="<your-client-secret>"
export ARM_TENANT_ID="<your-tenant-id>"
```

Set `CURRENT_IP_ADDRESS` in `creds.tfvars` (CIDR format, for example `203.0.113.10/32`) to include your current public IP in the Terraform allowlist used by storage account network rules.

### Variable Configuration

Key variables can be customized in `variables.tf`:
- `location` - Azure region (default: southcentralus)
- `resource_groups` - RG names to create (default: network, shared, cyclecloud)
- `vnet_address_space` - Virtual network CIDR (default: 10.100.0.0/16)
- `subnets` - Subnet definitions and address prefixes
- `tags` - Resource tags for organization and tracking

## Security

- Custom RBAC role with minimal required permissions
- Private DNS zones for internal service communication
- User-assigned managed identities for service authentication
- Encrypted storage accounts with secure blob services
- Log Analytics workspace with private endpoints for secure monitoring and diagnostics
- All diagnostic data routed through Log Analytics with dedicated private connectivity

## Monitoring and Diagnostics

The infrastructure includes comprehensive monitoring and diagnostics:

- **Log Analytics Workspace** - Centralized logging for all diagnostic data
- **Diagnostic Settings** - Configured for:
  - Azure Bastion Host
  - Key Vault
  - NAT Gateway
  - Public IP addresses
  - Virtual Network
  - Private Endpoints
- **Private DNS Zones** - For secure internal communication with Azure Monitor services:
  - `monitor.azure.com`
  - `ods.opinsights.azure.com`
  - `oms.opinsights.azure.com`
  - `agentservice.azure.com`
  - `blob.core.windows.net`
- **Azure Monitor Private Link Scope** - Enables private connectivity to monitoring services
- **Private Endpoints** - Secure connections to Log Analytics and monitoring services

## Files

- `providers.tf` - Terraform provider configuration
- `main.tf` - Core resource definitions (identity, roles, resource groups)
- `network.tf` - Virtual networking infrastructure
- `keyvault.tf` - Key Vault and secrets management with private endpoints
- `monitoring.tf` - Log Analytics workspace, diagnostic settings, and monitoring infrastructure
- `variables.tf` - Input variable definitions
- `locals.tf` - Local value definitions
- `.gitignore` - Git ignore patterns for Terraform artifacts
