# End-to-End Flow — Internet-Facing Demo

Public web + API App Services. MySQL private to the API only. No VPN. Infra-only (no real apps).

## Deploy

```bash
az login
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

./scripts/bootstrap.sh
# paste storage_account_name into each environments/*/backend.hcl

cd environments/dev
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan

terraform output frontend_url   # public web
terraform output api_url        # public API
```

Or run **Actions → Terraform CI** / **Terraform Apply** (`workflow_dispatch` only; secrets/OIDC later).

## Traffic

```
Internet / mobile → Web (public)
                  → API (public) → VNet → MySQL (private; API subnet NSG only)
```

## Modules

| Module | Purpose |
|--------|---------|
| `networking` | VNet, API/MySQL/PE subnets, NSGs, private DNS |
| `app-service` | Public web + API |
| `mysql` | Private Flexible Server |
| `key-vault` + `private-endpoint` | DB password; API identity only |
| `monitoring` | App Insights |
| `naming` | Name helpers |

## State

```hcl
resource_group_name  = "rg-tfstate-internetface"
storage_account_name = "<bootstrap>"
container_name       = "tfstate-dev"   # or qa / prod
key                  = "internetface.tfstate"
```

See [ENVIRONMENTS.md](ENVIRONMENTS.md) for CIDRs per env.
