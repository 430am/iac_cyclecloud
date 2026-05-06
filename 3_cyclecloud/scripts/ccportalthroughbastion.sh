#!/bin/bash
INFRA_DIR="$(dirname "$0")/../../1_infrastructure"
CYCLECLOUD_DIR="$(dirname "$0")/../"

resourceId=$(terraform -chdir="$CYCLECLOUD_DIR" output -raw cyclecloud_vm_id)
resourceGroup=$(echo "$resourceId" | cut -d'/' -f5)
bastion=$(terraform -chdir="$INFRA_DIR" output -raw bastion_host_name)

az network bastion tunnel --name "$bastion" --resource-group "$resourceGroup" --target-resource-id "$resourceId" --resource-port 443 --port 8443