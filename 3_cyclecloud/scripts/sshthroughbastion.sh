#!/bin/bash
INFRA_DIR="$(dirname "$0")/../../1_infrastructure"
CYCLECLOUD_DIR="$(dirname "$0")/../"

resourceId=$(terraform -chdir="$CYCLECLOUD_DIR" output -raw cyclecloud_vm_id)
resourceGroup=$(echo "$resourceId" | cut -d'/' -f5)
bastion=$(terraform -chdir="$INFRA_DIR" output -raw bastion_host_name)

kvName=$(terraform -chdir="$INFRA_DIR" output -raw key_vault_name)
kvSecretName=$(terraform -chdir="$INFRA_DIR" output -raw key_vault_private_key_secret_name)

tmpKey=$(mktemp)
trap 'rm -f "$tmpKey"' EXIT

az keyvault secret show \
  --vault-name "$kvName" \
  --name "$kvSecretName" \
  --query value \
  --output tsv > "$tmpKey"

chmod 600 "$tmpKey"

az network bastion ssh --name "$bastion" --resource-group "$resourceGroup" --target-resource-id "$resourceId" --auth-type ssh-key --username cyclecloudadmin --ssh-key "$tmpKey"