# 3_cyclecloud

Terraform configuration that deploys the CycleCloud runtime layer on top of the foundation from
`1_infrastructure` and the custom image published by `2_packer_image`.

## What this stage creates

- A CycleCloud server VM in the existing `CycleCloud` subnet, using the custom Shared Image Gallery image.
- The CycleCloud VM authenticates via SSH public key read from the Key Vault created in `1_infrastructure`.
- A blob storage account and private container for CycleLocker.
- A private endpoint for the CycleLocker blob service in the existing `PrivateEndpoints` subnet.
- Azure NetApp Files with:
  - `/sched` volume
  - `/share` volume
- ANF volumes mounted through the existing delegated `Storage` subnet from `1_infrastructure`.
- Azure Monitor Agent on the CycleCloud VM with a Data Collection Rule that sends Linux performance and syslog data to the Log Analytics workspace created in `1_infrastructure` (which is scoped through AMPLS).

## Dependencies

This stage expects:

1. `1_infrastructure` has already been applied and its local state file exists at `../1_infrastructure/terraform.tfstate`.
2. `2_packer_image` has published at least one image version into the SIG image definition from stage 1.

## Prerequisites

- Terraform >= 1.0
- Azure CLI or service principal credentials exported as `ARM_*` environment variables
- Existing VNet and subnets from `1_infrastructure`

## Variables

Important variables (see `variables.tf` for full list):

| Variable | Default | Description |
|---|---|---|
| `foundation_state_path` | `../1_infrastructure/terraform.tfstate` | Local state path for stage 1 outputs |
| `sig_image_version` | `latest` | Shared image version for CycleCloud VM |
| `cyclecloud_vm_size` | `Standard_D4ads_v6` | VM size for CycleCloud server |
| `anf_subnet_name` | `Storage` | Existing delegated ANF subnet name from `1_infrastructure` |
| `anf_sched_quota_gb` | `1024` | Capacity for `/sched` ANF volume |
| `anf_share_quota_gb` | `1024` | Capacity for `/share` ANF volume |

## Deployment

```bash
cd 3_cyclecloud/
cp environments/example.tfvars environments/creds.tfvars

# Ensure ARM_* credentials are exported in your shell.
terraform init
terraform plan -var-file=environments/creds.tfvars
terraform apply -var-file=environments/creds.tfvars
```

## Outputs

This stage returns:

- CycleCloud VM ID and private IP
- Key Vault secret name used for the CycleCloud SSH public key
- CycleLocker storage account name
- ANF mount target IPs for `/sched` and `/share`
