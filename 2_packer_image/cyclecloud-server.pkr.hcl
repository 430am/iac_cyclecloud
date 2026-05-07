packer {
  required_plugins {
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 2"
    }
  }
}

source "azure-arm" "cyclecloud_server" {
  use_azure_cli_auth = var.use_azure_cli_auth

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id != "" ? var.tenant_id : null
  client_id       = var.client_id != "" ? var.client_id : null
  client_secret   = var.client_secret != "" ? var.client_secret : null

  os_type         = "Linux"
  image_publisher = "microsoft-dsvm"
  image_offer     = "ubuntu-hpc"
  image_sku       = "2404"

  location                = var.location
  vm_size                 = var.build_vm_size
  ssh_username            = var.ssh_username

  shared_image_gallery_destination {
    resource_group = var.sig_resource_group_name
    gallery_name   = var.sig_name
    image_name     = var.sig_image_name
    image_version  = var.image_version != "" ? var.image_version : formatdate("YYYYMMDD.HHmm.ss", timestamp())
    replication_regions = var.replication_regions
    storage_account_type = var.sig_storage_account_type
  }
}

data "azure-keyvaultsecret" "cyclecloud_password" {
  use_azure_cli_auth = var.use_azure_cli_auth

  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id != "" ? var.tenant_id : null
  client_id       = var.client_id != "" ? var.client_id : null
  client_secret   = var.client_secret != "" ? var.client_secret : null

  vault_name  = var.key_vault_name
  secret_name = var.key_vault_password_secret_name
}

locals {
  cyclecloud_password_b64 = base64encode(data.azure-keyvaultsecret.cyclecloud_password.value)
}

build {
  name    = "cyclecloud-server"
  sources = ["source.azure-arm.cyclecloud_server"]

  # Wait for cloud-init to complete before provisioning.
  provisioner "shell" {
    inline = [
      "echo 'Waiting for cloud-init to complete...'",
      "cloud-init status --wait"
    ]
  }

  # Update the system and install base packages
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",
      "export DEBIAN_FRONTEND=noninteractive",
      # Wait for unattended-upgrades / cloud-init apt jobs to release the dpkg lock
      "for i in $(seq 1 60); do if ! fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock >/dev/null 2>&1; then break; fi; echo 'Waiting for apt lock...'; sleep 5; done",
      "systemctl stop unattended-upgrades.service apt-daily.timer apt-daily-upgrade.timer apt-daily.service apt-daily-upgrade.service 2>/dev/null || true",
      "systemctl disable unattended-upgrades.service apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true",
      "apt-get update -y",
      "apt-get upgrade -y",
      "apt-get install -y curl ca-certificates gnupg wget vim htop unzip jq net-tools lsb-release openjdk-8-jre"
    ]
  }

  # Install Microsoft signing key and package repository for Azure CLI and install the Azure CLI
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",
      "export DEBIAN_FRONTEND=noninteractive",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | bash"
    ]
  }

  # Install package repository for CycleCloud and install CycleCloud
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",
      "export DEBIAN_FRONTEND=noninteractive",
      "install -d -m 0755 /etc/apt/keyrings",
      "curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --batch --yes --dearmor -o /etc/apt/keyrings/microsoft.gpg",
      "chmod 0644 /etc/apt/keyrings/microsoft.gpg",
      "echo \"deb [signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/cyclecloud stable main\" | tee /etc/apt/sources.list.d/cyclecloud.list >/dev/null",
      "apt-get -qq update",
      # Make openjdk-8 the system default before installing CycleCloud (Ubuntu 24.04 ships Java 21)
      "test -x /usr/lib/jvm/java-8-openjdk-amd64/bin/java",
      "update-java-alternatives -s java-1.8.0-openjdk-amd64",
      "if apt-cache show cyclecloud8 >/dev/null 2>&1; then apt-get install -y cyclecloud8; elif apt-cache show cyclecloud >/dev/null 2>&1; then apt-get install -y cyclecloud; else echo 'CycleCloud package not found in Microsoft package feed.' >&2; exit 1; fi",
      # Pin CycleCloud to Java 8 explicitly so a future default-Java change doesn't break it
      "echo /usr/lib/jvm/java-8-openjdk-amd64 > /opt/cycle_server/config/java_home"
    ]
  }

  # Install and initialize the CycleCloud CLI, then create an Azure account config.
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E bash '{{ .Path }}'"
    inline = [
      "set -euo pipefail",
      "apt-get update -y",
      "apt-get install -yq unzip python3-venv",
      "CCPASSWORD=$(printf '%s' '${local.cyclecloud_password_b64}' | base64 -d)",
      "if [ -z \"$CCPASSWORD\" ]; then echo 'CCPASSWORD retrieved from Key Vault is empty.' >&2; exit 1; fi",
      "escaped_CCPASSWORD=$(printf '%s\n' \"$CCPASSWORD\" | sed -e 's/[\\/&]/\\\\&/g')",
      "cat >/tmp/cyclecloud_account.json <<'EOF'\n[\n  {\n    \"AdType\": \"Application.Setting\",\n    \"Name\": \"cycleserver.installation.initial_user\",\n    \"Value\": \"${var.ssh_username}\"\n  },\n  {\n    \"AdType\": \"AuthenticatedUser\",\n    \"Name\": \"${var.ssh_username}\",\n    \"RawPassword\": \"CCPASSWORD_PLACEHOLDER\",\n    \"Superuser\": true\n  },\n  {\n    \"AdType\": \"Application.Setting\",\n    \"Name\": \"cycleserver.installation.complete\",\n    \"Value\": true\n  }\n]\nEOF",
      "sed -i \"s/CCPASSWORD_PLACEHOLDER/$escaped_CCPASSWORD/g\" /tmp/cyclecloud_account.json",
      "install -o root -g root -m 0600 /tmp/cyclecloud_account.json /opt/cycle_server/config/data/cyclecloud_account.json",
      "rm -f /tmp/cyclecloud_account.json",
      "/opt/cycle_server/cycle_server await_startup",
      "unzip -o /opt/cycle_server/tools/cyclecloud-cli.zip -d /tmp",
      "python3 /tmp/cyclecloud-cli-installer/install.py -y --installdir /home/${var.ssh_username}/.cycle --system",
      "initialize_ok=false",
      "for i in $(seq 1 12); do if CCPASSWORD=\"$CCPASSWORD\" runuser -l ${var.ssh_username} -c '/usr/local/bin/cyclecloud initialize --loglevel=debug --batch --url=http://localhost:8080 --verify-ssl=false --username=${var.ssh_username} --password=\"$CCPASSWORD\"'; then initialize_ok=true; break; fi; echo 'cyclecloud initialize attempt failed; retrying...'; sleep 10; done",
      "if [ \"$initialize_ok\" != \"true\" ]; then install -d -m 0700 -o ${var.ssh_username} -g ${var.ssh_username} /home/${var.ssh_username}/.cycle; cat >/home/${var.ssh_username}/.cycle/config.ini <<EOF\n[cyclecloud]\nurl = http://localhost:8080\nusername = ${var.ssh_username}\npassword = $CCPASSWORD\nverify_certificates = false\nverify-ssl = false\nEOF\nchmod 0600 /home/${var.ssh_username}/.cycle/config.ini\nchown ${var.ssh_username}:${var.ssh_username} /home/${var.ssh_username}/.cycle/config.ini; fi",
      "effective_tenant_id=\"${var.cyclecloud_tenant_id}\"",
      "if [ -z \"$effective_tenant_id\" ] && [ -n \"${var.tenant_id}\" ]; then effective_tenant_id=\"${var.tenant_id}\"; fi",
      "if [ -z \"$effective_tenant_id\" ]; then echo 'cyclecloud_tenant_id (or tenant_id) must be set to create the CycleCloud account file.' >&2; exit 1; fi",
      "cat >/opt/cycle_server/azure_subscription.json <<EOF\n{\n  \"Environment\": \"public\",\n  \"AzureRMUseManagedIdentity\": true,\n  \"AzureRMSubscriptionId\": \"${var.subscription_id}\",\n  \"AzureRMTenantId\": \"$effective_tenant_id\",\n  \"DefaultAccount\": true,\n  \"Location\": \"${var.location}\",\n  \"Name\": \"${var.cyclecloud_account_name}\",\n  \"Provider\": \"azure\",\n  \"ProviderId\": \"${var.subscription_id}\",\n  \"AcceptMarketplaceTerms\": true\n}\nEOF",
      "runuser -l ${var.ssh_username} -c '/usr/local/bin/cyclecloud account create -f /opt/cycle_server/azure_subscription.json'"
    ]
  }

  # Prepare the VM for image capture.
  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E bash '{{ .Path }}'"
    inline = [
      "set -euxo pipefail",
      "apt-get clean",
      "rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*",
      "waagent -force -deprovision+user || true",
      "cloud-init clean --logs || true",
      "truncate -s 0 /etc/machine-id",
      "sync",
    ]
  }
}