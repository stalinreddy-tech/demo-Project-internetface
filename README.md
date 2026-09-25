# Enterprise Private 3-Tier Azure Platform (Terraform)

Terraform-only platform to host an **internal** enterprise app on Azure. This learning repo focuses on **one environment: `dev`**.

| Tier | Runtime | Network exposure |
|------|---------|------------------|
| **Frontend** | Linux App Service (React / Vite / Node) | Private only — VPN + Private Endpoint |
| **Backend** | Linux App Service (Node.js API) | Private only — reachable from **frontend subnet** |
| **Data** | Azure Database for MySQL Flexible Server | Private only — reachable from **backend subnet** |

No application source code lives here. Deploy your apps separately to the App Services this stack creates.

**Start here for a full walkthrough:** [docs/END-TO-END-FLOW.md](docs/END-TO-END-FLOW.md)

---

## Quick mental model

```
1. bootstrap/     → creates Azure Storage for Terraform *state* (not the app)
2. Fill backend.hcl with the storage account name
3. environments/dev → terraform init / plan / apply → creates the private 3-tier stack
4. Connect with Azure VPN Client → open the frontend hostname
```

```
 You (laptop)
    |
    | Azure VPN Client
    v
 [VPN Gateway] ── only public IP is for VPN, not the app
    |
    v
 [Private Endpoint] → Frontend App Service
    |  (VNet integration / proxy /api)
    v
 [Private Endpoint] → Backend App Service  (allow FE subnet only)
    |  (VNet integration)
    v
 [snet-mysql] → MySQL Flexible Server
```

---

## Repository layout

```
bootstrap/                 # One-time: Storage Account + tfstate-dev container
modules/                   # Reusable building blocks (networking, vpn, apps, …)
environments/
  dev/                     # The only env in this learning path
    main.tf                # Wires all modules
    terraform.tfvars       # SKUs, CIDRs, flags
    backend.hcl            # Where Terraform stores remote state
    versions.tf            # Partial backend "azurerm" {}
.github/workflows/
  terraform-ci.yml         # fmt, validate, plan (dev)
  terraform-apply.yml      # manual apply (dev)
scripts/
  bootstrap.sh
  plan-env.sh              # defaults to dev
docs/
  END-TO-END-FLOW.md       # Thorough learner walkthrough
```

> Want more envs later? Copy `environments/dev` → `environments/qa`, add a `tfstate-qa` container in bootstrap, and extend the GitHub workflows. Comments in those files point the way.

---

## Prerequisites

1. Azure subscription with rights to create networking, App Service, MySQL, Key Vault, VPN Gateway  
2. Terraform `>= 1.5`  
3. Azure CLI (`az login`) for local runs  
4. (Optional CI) GitHub Environment named `dev` + OIDC secrets — see [END-TO-END-FLOW.md](docs/END-TO-END-FLOW.md#5-how-the-github-actions-pipeline-works)

> **Cost tip:** VPN Gateway and MySQL are the expensive pieces. Set `enable_vpn = false` in `environments/dev/terraform.tfvars` while you experiment with App Service / MySQL only.

---

## Deploy `dev` in 5 steps (local)

```bash
# 0. Login
az login
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

# 1. Create remote state storage (once)
./scripts/bootstrap.sh
# OR: cd bootstrap && cp terraform.tfvars.example terraform.tfvars && terraform init && terraform apply

# 2. Paste storage_account_name into environments/dev/backend.hcl

# 3. Plan
./scripts/plan-env.sh          # defaults to dev
# OR: cd environments/dev && terraform init -backend-config=backend.hcl
#     && terraform plan -var-file=terraform.tfvars -out=tfplan

# 4. Apply (VPN Gateway can take 30–45+ minutes)
cd environments/dev && terraform apply tfplan

# 5. Connect via Azure VPN Client, then open:
terraform output frontend_hostname
```

Details, diagrams, every resource, and CI explanation: **[docs/END-TO-END-FLOW.md](docs/END-TO-END-FLOW.md)**.

---

## Resources created (`dev`)

| Resource | Where | Purpose |
|----------|-------|---------|
| Resource Group | env root | Holds all `dev` resources |
| VNet + subnets + NSGs + Private DNS | `modules/networking` | Tier isolation + private name resolution |
| VPN Gateway + Public IP | `modules/vpn` | Point-to-Site access for internal users |
| Frontend / Backend App Service + Plans | `modules/app-service` | Private web + API |
| Private Endpoints (FE, BE, Key Vault) | `modules/private-endpoint` | Private inbound to PaaS |
| MySQL Flexible Server + DB | `modules/mysql` | Private data tier |
| Key Vault + secrets | `modules/key-vault` | MySQL password & connection string |
| Log Analytics + App Insights | `modules/monitoring` | Logs and metrics |
| State RG + Storage + `tfstate-dev` | `bootstrap/` | Remote Terraform state (once) |

Default `dev` network: VNet `10.10.0.0/16`, VPN clients `172.16.10.0/24`.

---

## Outputs (after apply)

- `frontend_hostname` — URL for VPN users  
- `backend_hostname` — API host (from frontend subnet only)  
- `mysql_fqdn` — private MySQL hostname  
- `vpn_public_ip` — VPN gateway IP (profile / control plane only)  
- `key_vault_uri` — secrets store  

---

## Security highlights

- No public inbound to frontend, backend, or MySQL  
- NSG: MySQL **3306** only from backend subnet; backend HTTP(S) only from frontend subnet  
- Backend App Service access restriction mirrors “FE subnet only”  
- TLS 1.2+, FTPS disabled, HTTPS only  
- Key Vault RBAC; apps use managed identity + Key Vault references  
- State storage: private container, blob versioning, soft delete  

**App note:** Browser → backend direct calls are blocked by design. Frontend should **proxy** `/api` to the backend (BFF pattern).

---

## License / intent

Learning / demo enterprise layout for a private 3-tier App Service + MySQL stack on Azure, with remote state and GitHub Actions OIDC — simplified to **`dev` only**.
