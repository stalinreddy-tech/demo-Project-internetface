# Internet-Facing 3-Tier Azure Platform (Terraform)

Azure **infra-only** demo: public web + API App Services; private MySQL for the API only.
No real frontend/mobile code. No VPN.

**Environments:** `dev` · `qa` · `prod`

| Tier | Runtime | Exposure |
|------|---------|----------|
| **Web** | Linux App Service | Public HTTPS |
| **API** | Linux App Service | Public HTTPS (web + mobile) |
| **Data** | MySQL Flexible Server | Private — API subnet only |

**Walkthrough:** [docs/END-TO-END-FLOW.md](docs/END-TO-END-FLOW.md)

---

## Architecture

```
Internet / mobile ──HTTPS──► Web App Service
                 ──HTTPS──► API App Service
                                │ VNet integration
                                ▼
                           MySQL (private)
```

---

## Modules kept

```
modules/
  naming/
  networking/      # VNet, snet-api, snet-mysql, PE subnet, NSGs, private DNS
  app-service/     # Web + API
  mysql/
  key-vault/
  private-endpoint/  # Key Vault only
  monitoring/
```

Removed: `vpn` (not used for internet-facing).

---

## Fresh local setup

```bash
az login
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

# 1) Bootstrap state storage (once)
./scripts/bootstrap.sh

# 2) Paste storage_account_name into environments/{dev,qa,prod}/backend.hcl

# 3) Init + plan + apply (example: dev)
cd environments/dev
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan

terraform output frontend_url
terraform output api_url
```

State: `rg-tfstate-internetface` / containers `tfstate-*` / key `internetface.tfstate`.

---

## CI/CD

Both workflows are **manual only** (`workflow_dispatch`) — no push/PR triggers. Secrets and OIDC can be wired later.

| Workflow | Action |
|----------|--------|
| `Terraform CI` | fmt, validate, plan (pick env or all) |
| `Terraform Apply` | plan + apply one env (type env name to confirm) |

Secrets (when ready): `TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT`, `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`  
GitHub Environments: `dev`, `qa`, `prod`
