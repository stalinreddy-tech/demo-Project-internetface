#!/usr/bin/env bash
# Bootstrap remote state storage once, then print backend.hcl values for dev.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/bootstrap"

echo "==> Initializing bootstrap..."
terraform init -input=false
terraform apply -input=false -auto-approve

SA=$(terraform output -raw storage_account_name)
RG=$(terraform output -raw resource_group_name)
CN=$(terraform output -raw container_name)

echo ""
echo "==> Update environments/dev/backend.hcl with:"
echo "resource_group_name  = \"${RG}\""
echo "storage_account_name = \"${SA}\""
echo "container_name       = \"${CN}\""
echo "key                  = \"enterprise.tfstate\""
echo ""
echo "==> GitHub Actions secrets to set:"
echo "TF_STATE_RESOURCE_GROUP=${RG}"
echo "TF_STATE_STORAGE_ACCOUNT=${SA}"
echo ""
echo "Also configure OIDC app registration secrets:"
echo "  AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID"
