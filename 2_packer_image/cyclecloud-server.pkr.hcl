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
    image_version  = var.image_version
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
    inline = [
      "set -euxo pipefail",
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y curl ca-certificates gnupg wget vim htop unzip jq net-tools lsb-release"
    ]
  }

  # Install Microsoft signing key and package repository for Azure CLI and install the Azure CLI
  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      "export DEBIAN_FRONTEND=noninteractive",
      "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash"
    ]
  }

  # Install package repository for CycleCloud and install CycleCloud
  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      "export DEBIAN_FRONTEND=noninteractive",
      "echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/repos/cyclecloud main' | sudo tee /etc/apt/sources.list.d/cyclecloud.list >/dev/null",
      "sudo apt-get update",
      "if apt-cache show cyclecloud8 >/dev/null 2>&1; then sudo apt-get install -y cyclecloud8; elif apt-cache show cyclecloud >/dev/null 2>&1; then sudo apt-get install -y cyclecloud; else echo 'CycleCloud package not found in Microsoft package feed.' >&2; exit 1; fi"
    ]
  }

  # Prepare the VM for image capture.
  provisioner "shell" {
    inline = [
      "set -euxo pipefail",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*",
      "sudo waagent -force -deprovision+user || true",
      "sudo cloud-init clean --logs || true",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo sync",
    ]
  }
}