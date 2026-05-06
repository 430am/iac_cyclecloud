# IAC CycleCloud

Infrastructure-as-Code for deploying Azure CycleCloud using Terraform and Packer.

## Repository structure

| Folder | Tool | Purpose |
|---|---|---|
| [`1_infrastructure/`](1_infrastructure/README.md) | Terraform | Core Azure infrastructure — networking, identity, Key Vault, Shared Image Gallery, and monitoring |
| [`2_packer_image/`](2_packer_image/README.md) | Packer | Custom CycleCloud server image built on Ubuntu 24.04 DSVM and published to the SIG |
| [`3_cyclecloud/`](3_cyclecloud/README.md) | Terraform | CycleCloud runtime stack — CycleCloud VM, CycleLocker storage, and Azure NetApp Files volumes |

## Deployment order

These three stages must be run in order. Stage 2 depends on the Shared Image Gallery from stage 1, and stage 3 depends on both stage 1 outputs and the stage 2 published image.

```
1_infrastructure  →  2_packer_image  →  3_cyclecloud
(Terraform)            (Packer)          (Terraform)
```

### Stage 1 — Infrastructure

```bash
cd 1_infrastructure/
cp environments/example.tfvars environments/creds.tfvars
# Fill in credentials and CURRENT_IP_ADDRESS in creds.tfvars

export ARM_SUBSCRIPTION_ID="<subscription-id>"
export ARM_CLIENT_ID="<client-id>"
export ARM_CLIENT_SECRET="<client-secret>"
export ARM_TENANT_ID="<tenant-id>"

terraform init
terraform apply -var-file=environments/creds.tfvars
```

### Stage 2 — CycleCloud image

```bash
cd 2_packer_image/
cp environments/example.pkrvars.hcl environments/creds.pkrvars.hcl
# Fill in subscription_id and SIG values from terraform output:
#   cd ../1_infrastructure
#   terraform output -raw resource_group_name
#   terraform output -raw sig_name
#   terraform output -raw sig_image_name

az login
packer init cyclecloud-server.pkr.hcl
packer build -var-file=environments/creds.pkrvars.hcl cyclecloud-server.pkr.hcl
```

### Stage 3 — CycleCloud runtime stack

```bash
cd 3_cyclecloud/
cp environments/example.tfvars environments/creds.tfvars

terraform init
terraform apply -var-file=environments/creds.tfvars
```

## Prerequisites

| Tool | Minimum version |
|---|---|
| Terraform | 1.0 |
| Packer | 1.9 |
| Azure CLI | any recent |

The deploying identity needs permission to create resources and assign RBAC roles at subscription scope.

## Security notes

- All credential files (`creds.tfvars`, `creds.pkrvars.hcl`) are git-ignored.
- Key Vault stores VM passwords and SSH keys generated ephemerally at `terraform apply` time.
- CycleCloud uses a least-privilege custom RBAC role.
- Azure Monitor connectivity is private via a Monitor Private Link Scope.
- Bastion provides SSH/RDP access without exposing VMs to the public internet.

## Detailed documentation

- [1_infrastructure/README.md](1_infrastructure/README.md) — infrastructure components, variables, outputs, and deployment steps
- [2_packer_image/README.md](2_packer_image/README.md) — image build process, variables, authentication, and deployment steps
- [3_cyclecloud/README.md](3_cyclecloud/README.md) — CycleCloud server, storage, ANF, private connectivity, and Azure Monitor Agent deployment
