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
  image_publisher = "Canonical"
  image_offer     = "ubuntu-24_04-lts"
  image_sku       = "server"

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