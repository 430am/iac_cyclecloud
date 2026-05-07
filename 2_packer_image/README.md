# 2_packer_image

Packer template that builds a custom CycleCloud server image on top of the Ubuntu 24.04 DSVM
base image (`microsoft-dsvm/ubuntu-hpc/2404`) and publishes the result as a versioned image
in the Shared Image Gallery created by `1_infrastructure`.

## What the build does

1. Starts a temporary Azure VM from the `ubuntu-hpc 2404` marketplace image (in an ephemeral resource group, VNet, and public IP managed by Packer).
2. Waits for cloud-init to finish, then disables `unattended-upgrades` and the `apt-daily` timers so they don't hold the dpkg lock during the build.
3. Updates the system and installs base packages (`curl`, `gnupg`, `jq`, `lsb-release`, `openjdk-8-jre`, etc.).
4. Installs **Azure CLI** via the official Microsoft install script.
5. Adds the Microsoft `packages.microsoft.com/repos/cyclecloud stable` repository (signed-by `/etc/apt/keyrings/microsoft.gpg`), pins openjdk-8 as the system default with `update-java-alternatives`, then installs **CycleCloud** (`cyclecloud8` or `cyclecloud`).
6. Writes `/opt/cycle_server/config/java_home = /usr/lib/jvm/java-8-openjdk-amd64` so a future default-Java change won't break CycleCloud.
7. Cleans apt caches, runs `waagent -deprovision+user` and `cloud-init clean` to generalise the VM.
8. Publishes the resulting image version to the target Shared Image Gallery definition.

## Prerequisites

- [Packer](https://developer.hashicorp.com/packer/install) >= 1.9
- Azure CLI (`az`) — only required when using `use_azure_cli_auth = true` (the default)
- `1_infrastructure` must already be deployed so the target gallery and image definition exist

## Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `subscription_id` | yes | — | Azure subscription ID |
| `location` | no | `southcentralus` | Region for the temporary build VM |
| `build_vm_size` | no | `Standard_D4ads_v6` | VM size for the Packer build agent |
| `ssh_username` | no | `azureuser` | SSH user Packer uses to connect |
| `image_version` | no | `""` | Optional SIG image version override (`major.minor.patch`); when unset a unique timestamp-based version is generated each build |
| `sig_resource_group_name` | yes | — | Resource group containing the SIG |
| `sig_name` | yes | — | Shared Image Gallery name |
| `sig_image_name` | yes | — | Image definition name within the gallery |
| `replication_regions` | no | `["southcentralus"]` | Regions to replicate the image version to |
| `sig_storage_account_type` | no | `Standard_LRS` | Storage tier for the image version artifacts |
| `key_vault_name` | yes | `""` | Key Vault name from `1_infrastructure` |
| `key_vault_password_secret_name` | yes | `""` | Secret name containing `CCPASSWORD` |
| `cyclecloud_tenant_id` | conditional | `""` | Tenant ID used in the generated CycleCloud account file (required if `tenant_id` is unset) |
| `cyclecloud_account_name` | no | `default` | CycleCloud account name created during build |
| `use_azure_cli_auth` | no | `true` | Authenticate with `az login` session |
| `tenant_id` | no | `""` | Tenant ID (service principal auth only) |
| `client_id` | no | `""` | Client ID (service principal auth only) |
| `client_secret` | no | `""` | Client secret (service principal auth only) |

## Authentication

By default the template uses your active `az login` session (`use_azure_cli_auth = true`).
To use a service principal instead, set `use_azure_cli_auth = false` and provide
`tenant_id`, `client_id`, and `client_secret` in your var file.

The service principal or user identity running Packer needs:
- **Contributor** on the target resource group (to create the temporary build VM and its resources)
- **Contributor** or **Gallery Image Version Contributor** on the Shared Image Gallery

## Deployment

### 1. Deploy 1_infrastructure first

The Shared Image Gallery and image definition must exist before the Packer build runs.
See [1_infrastructure/README.md](../1_infrastructure/README.md).

### 2. Retrieve gallery names from Terraform outputs

```bash
cd ../1_infrastructure/
RG_NAME=$(terraform output -raw resource_group_name)
SIG_NAME=$(terraform output -raw sig_name)
SIG_IMAGE_NAME=$(terraform output -raw sig_image_name)
KV_NAME=$(terraform output -raw key_vault_name)
KV_PASSWORD_SECRET=$(terraform output -raw key_vault_password_secret_name)
echo "sig_resource_group_name = \"$RG_NAME\""
echo "sig_name                = \"$SIG_NAME\""
echo "sig_image_name          = \"$SIG_IMAGE_NAME\""
echo "key_vault_name                = \"$KV_NAME\""
echo "key_vault_password_secret_name = \"$KV_PASSWORD_SECRET\""
```

### 3. Create a local var file

```bash
cp environments/example.pkrvars.hcl environments/creds.pkrvars.hcl
```

Edit `environments/creds.pkrvars.hcl` and populate at minimum:

```hcl
subscription_id         = "<your-subscription-id>"
sig_resource_group_name = "<rg-name from step 2>"
sig_name                = "<sig-name from step 2>"
sig_image_name          = "<image-name from step 2>"
key_vault_name                = "<key-vault-name from step 2>"
key_vault_password_secret_name = "<password-secret-name from step 2>"
cyclecloud_tenant_id          = "<tenant-id>"
```

### 4. Initialise and build

```bash
cd 2_packer_image/
az login                          # only needed when use_azure_cli_auth = true
packer init .
packer validate -var-file=environments/creds.pkrvars.hcl .
packer build    -var-file=environments/creds.pkrvars.hcl .
```

> Always invoke Packer against the **directory** (`.`) rather than a single file, so it loads `variables.pkr.hcl` alongside the source/build blocks.

### Updating an existing image

By default, each run auto-generates a unique image version in the format `YYYYMMDD.HHMM.SS`.
If you need deterministic versioning, set `image_version` explicitly in your var file (for example `1.0.1`) and re-run `packer build`.

## Files

| File | Purpose |
|---|---|
| `cyclecloud-server.pkr.hcl` | Packer source block, provisioner steps, and build definition |
| `variables.pkr.hcl` | All input variable declarations |
| `environments/example.pkrvars.hcl` | Template var file — copy to `creds.pkrvars.hcl` and fill in values |
