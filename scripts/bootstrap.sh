#!/usr/bin/env bash
# Bootstrap remote state storage once (or re-apply to add qa/prod containers).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/bootstrap"

echo "==> Initializing bootstrap..."
terraform init -input=false
terraform apply -input=false -auto-approve

SA=$(terraform output -raw storage_account_name)
RG=$(terraform output -raw resource_group_name)

echo ""
echo "==> Update EACH environments/{dev,qa,prod}/backend.hcl with:"
echo "resource_group_name  = \"${RG}\""
echo "storage_account_name = \"${SA}\""
echo "key                  = \"internetface.tfstate\""
echo ""
echo "Use a different container_name per env:"
echo "  environments/dev/backend.hcl  → container_name = \"tfstate-dev\""
echo "  environments/qa/backend.hcl   → container_name = \"tfstate-qa\""
echo "  environments/prod/backend.hcl → container_name = \"tfstate-prod\""
echo ""
echo "==> GitHub Actions secrets to set:"
echo "TF_STATE_RESOURCE_GROUP=${RG}"
echo "TF_STATE_STORAGE_ACCOUNT=${SA}"
echo ""
echo "Also configure OIDC app registration secrets:"
echo "  AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID"
echo "Create GitHub Environments: dev, qa, prod (approvals recommended for prod)."
