# End-to-End Flow — Dev Environment (Learner Guide)

This document walks you from an empty Azure subscription to a running **private** 3-tier stack, using **only the `dev` environment**.

If multi-env folders (`qa`, `staging`, `prod`, …) confused you before: they are gone. One path. One state container. One set of commands.

---

## Table of contents

1. [E2E flow (zero → deployed)](#1-e2e-flow-zero--deployed)
2. [Every resource, by module](#2-every-resource-by-module)
3. [How remote state is configured “dynamically”](#3-how-remote-state-is-configured-dynamically)
4. [How to run from your terminal](#4-how-to-run-from-your-terminal)
5. [How the GitHub Actions pipeline works](#5-how-the-github-actions-pipeline-works)

---

## 1. E2E flow (zero → deployed)

### Big picture

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP A — Bootstrap (run once)                                  │
│  bootstrap/                                                     │
│    → rg-tfstate-enterprise                                      │
│    → Storage Account (random name, e.g. sttfstateabc123)        │
│    → Container: tfstate-dev                                     │
│  This stores Terraform *state files*, not your app.             │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP B — Point Terraform at that storage                       │
│  Edit environments/dev/backend.hcl                              │
│    storage_account_name = "<from bootstrap output>"             │
│    container_name       = "tfstate-dev"                         │
│    key                  = "enterprise.tfstate"                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP C — Deploy the app platform                               │
│  cd environments/dev                                            │
│  terraform init -backend-config=backend.hcl                     │
│  terraform plan  -var-file=terraform.tfvars -out=tfplan         │
│  terraform apply tfplan                                         │
│                                                                 │
│  Creates: RG, VNet, NSGs, DNS, VPN, App Services, MySQL,        │
│           Key Vault, Private Endpoints, Monitoring              │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP D — Access the app                                        │
│  1. Download VPN client profile from the VPN Gateway            │
│  2. Connect with Azure VPN Client                               │
│  3. Open https://<frontend_hostname>                            │
│     (terraform output frontend_hostname)                        │
└─────────────────────────────────────────────────────────────────┘
```

### Traffic after deploy

```
 Internal user (you)
      |
      |  Azure VPN Client (P2S)
      v
 [VPN Gateway] ---- public IP is ONLY for VPN control plane
      |
      |  private VNet (10.10.0.0/16 in dev)
      v
 [Private Endpoint] ---> Frontend App Service
      |                  public_network_access = Disabled
      |  VNet Integration (outbound from snet-frontend)
      |  App should proxy /api/* to backend (BFF)
      v
 [Private Endpoint] ---> Backend App Service
                         Access Restriction: Allow snet-frontend ONLY
      |
      |  VNet Integration (outbound from snet-backend)
      v
 [Delegated snet-mysql] ---> MySQL Flexible Server (no public access)
```

### What “success” looks like

| Check | How |
|-------|-----|
| State exists | Blob `enterprise.tfstate` inside container `tfstate-dev` |
| Stack exists | Resource group like `rg-ente-dev-eus` in Azure Portal |
| VPN works | Azure VPN Client connected; you get an IP from `172.16.10.0/24` |
| Frontend opens | `https://<frontend_hostname>` loads over VPN (not from public internet) |

---

## 2. Every resource, by module

All of these are wired together in `environments/dev/main.tf`.

### Shared once — `bootstrap/`

| Resource | Name / pattern | Why it exists |
|----------|----------------|---------------|
| Resource Group | `rg-tfstate-enterprise` | Holds the state storage account |
| Storage Account | `sttfstate??????` (random suffix) | Remote Terraform state + locking |
| Blob container | `tfstate-dev` | Isolates `dev` state (one blob key: `enterprise.tfstate`) |

**Not** part of your app. Think of it as Terraform’s notebook in the cloud.

---

### Env root — `environments/dev/main.tf` (not a module)

| Resource | Why |
|----------|-----|
| `random_string.suffix` | Makes globally unique App Service / MySQL / Key Vault names |
| `azurerm_resource_group.this` | Container for everything in `dev` (name from naming module) |
| `azurerm_role_assignment` (FE + BE → Key Vault Secrets User) | Lets each App Service managed identity read secrets |

---

### `modules/naming`

| What | Why |
|------|-----|
| Local name map (`rg-…`, `vnet-…`, `app-fe-…`, etc.) | Consistent, predictable Azure names from `project` + `environment` + region short code |

No Azure resources — naming helpers only.

---

### `modules/networking`

| Resource | Why / how it connects |
|----------|----------------------|
| **Virtual Network** | Private network for all tiers (`10.10.0.0/16` in `terraform.tfvars`) |
| **Subnet `snet-frontend`** | VNet Integration for the frontend App Service (delegated to `Microsoft.Web/serverFarms`) |
| **Subnet `snet-backend`** | VNet Integration for the backend App Service |
| **Subnet `snet-mysql`** | Dedicated delegated subnet for MySQL Flexible Server |
| **Subnet `snet-private-endpoints`** | Hosts Private Endpoint NICs for FE, BE, Key Vault |
| **Subnet `GatewaySubnet`** | Required by Azure for the VPN Gateway |
| **NSG frontend** | Allow HTTP/HTTPS from VNet; deny internet inbound |
| **NSG backend** | Allow HTTP/HTTPS **only from frontend subnet**; deny everything else inbound |
| **NSG data (MySQL)** | Allow **3306 only from backend subnet**; deny other inbound |
| **NSG private endpoints** | Allow HTTPS from VNet; deny internet inbound |
| **NSG ↔ subnet associations** | Attach each NSG to its subnet |
| **Private DNS `privatelink.azurewebsites.net`** | Resolve App Service hostnames to private IPs over VPN/VNet |
| **Private DNS `privatelink.mysql.database.azure.com`** | Private MySQL name resolution (link pattern) |
| **Private DNS `privatelink.vaultcore.azure.net`** | Private Key Vault name resolution |
| **Private DNS MySQL Flexible zone** | Custom zone name for MySQL VNet integration hostname |
| **VNet links** for each DNS zone | Attach zones to this VNet so VPN clients resolve correctly |

---

### `modules/vpn` (optional via `enable_vpn`)

| Resource | Why / how it connects |
|----------|----------------------|
| **Public IP** | Control-plane endpoint for Point-to-Site VPN (not for serving the web app) |
| **Virtual Network Gateway** | Lets your laptop join the VNet; then you reach Private Endpoints |

Auth: Entra ID if `aad_tenant_id` is set; otherwise certificate-based P2S.

---

### `modules/monitoring`

| Resource | Why |
|----------|-----|
| **Log Analytics workspace** | Central log store |
| **Application Insights** | App telemetry; connection string injected into both App Services |

---

### `modules/mysql`

| Resource | Why / how it connects |
|----------|----------------------|
| **random_password** | Strong admin password (stored in Key Vault, not typed by you) |
| **MySQL Flexible Server** | Data tier; lives in `snet-mysql` with private DNS — **no public access** |
| **MySQL database `appdb`** | Default application database |
| **Config `require_secure_transport=ON`** | Force TLS to MySQL |

Backend reaches it via VNet Integration + NSG allow on 3306.

---

### `modules/key-vault`

| Resource | Why / how it connects |
|----------|----------------------|
| **Key Vault** | Stores `mysql-admin-password` and `mysql-connection` |
| **Role: Key Vault Administrator** (your Terraform identity) | So apply can create secrets |
| **Secrets** | Values come from the MySQL module outputs |
| **Private Endpoint** (created in env root via `pe_key_vault`) | Private data-plane access from the VNet |

Apps read secrets with managed identity + Key Vault references (see backend `app_settings`).

---

### `modules/app-service` (used twice: frontend + backend)

| Resource | Why |
|----------|-----|
| **App Service Plan** | Compute SKU for the Linux web app (`P0v3` in `dev` tfvars) |
| **Linux Web App** | Hosts FE or BE; `public_network_access_enabled = false` |
| **System-assigned identity** | Used for Key Vault access |
| **VNet Integration** | Outbound traffic into `snet-frontend` or `snet-backend` |
| **IP restrictions (backend only)** | Allow traffic only from the frontend subnet |
| **App settings** | FE gets `BACKEND_URL`; BE gets `DB_*` + Key Vault password reference |
| **App Insights settings** | Telemetry wired from monitoring module |

---

### `modules/private-endpoint` (used three times)

| Instance | Target | Why |
|----------|--------|-----|
| `pe_frontend` | Frontend Web App (`sites`) | VPN/VNet users reach FE on a private IP |
| `pe_backend` | Backend Web App (`sites`) | FE (via VNet) reaches BE privately |
| `pe_key_vault` | Key Vault (`vault`) | Secrets over private link |

Each PE sits in `snet-private-endpoints` and registers into the matching Private DNS zone.

---

### How the pieces connect (summary)

```
naming ──► names for everything
    │
networking ──► VNet / subnets / NSGs / DNS
    │
    ├── vpn (GatewaySubnet)
    ├── mysql (snet-mysql + flexible DNS)
    ├── frontend app (VNet integ → snet-frontend) + PE
    ├── backend app  (VNet integ → snet-backend)  + PE
    │       └── Key Vault reference for DB password
    ├── key-vault + PE
    └── monitoring → App Insights connection strings on both apps
```

---

## 3. How remote state is configured “dynamically”

Terraform needs somewhere to save “what I already created.” That file is **state**. We store it in Azure Blob Storage so your laptop and GitHub Actions share the same truth.

### Two different jobs (plain language)

| Piece | Job |
|-------|-----|
| **`bootstrap/`** | Creates the Storage Account + `tfstate-dev` container. Run **once**. Uses **local** state (or its own default) — it is *not* the app stack. |
| **`environments/dev/backend.hcl`** | Tells the **app** Terraform root: “put my state in *that* storage account, container `tfstate-dev`, blob key `enterprise.tfstate`.” |

Bootstrap builds the filing cabinet. `backend.hcl` is the label on the drawer you use for `dev`.

### Partial backend in code

File: `environments/dev/versions.tf`

```hcl
backend "azurerm" {
  # Partial config — values supplied via backend.hcl during init:
  #   terraform init -backend-config=backend.hcl
}
```

The block is **empty on purpose**. Values are not hard-coded in Git (storage names are random / secret-ish). You supply them at `init` time.

### Exact values for `dev`

File: `environments/dev/backend.hcl`

```hcl
resource_group_name  = "rg-tfstate-enterprise"
storage_account_name = "REPLACE_WITH_BOOTSTRAP_STORAGE_ACCOUNT"  # ← paste from bootstrap
container_name       = "tfstate-dev"
key                  = "enterprise.tfstate"
```

| Setting | Meaning |
|---------|---------|
| `resource_group_name` | Where the storage account lives |
| `storage_account_name` | From `terraform output storage_account_name` in `bootstrap/` |
| `container_name` | Always `tfstate-dev` in this learning repo |
| `key` | Blob name for this stack’s state file |

### Exact init command

```bash
cd environments/dev
terraform init -backend-config=backend.hcl
```

What happens:

1. Terraform reads `backend "azurerm" {}` from `versions.tf`
2. Merges settings from `backend.hcl`
3. Connects to Azure Storage and uses blob `tfstate-dev/enterprise.tfstate`

### Later: more environments

Today: **one** container `tfstate-dev`.  
Later: add `tfstate-qa` (etc.) in bootstrap, copy `environments/dev` → `environments/qa`, change that folder’s `backend.hcl` `container_name`. Same pattern — still “dynamic” via `-backend-config`.

---

## 4. How to run from your terminal

### Prerequisites on your machine

```bash
az --version          # Azure CLI
terraform version     # >= 1.5
az login
az account set --subscription "<your-subscription-id>"
export ARM_SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
```

Optional (Entra ID VPN auth):

```bash
export TF_VAR_aad_tenant_id="$(az account show --query tenantId -o tsv)"
```

### Step 1 — Bootstrap state storage

**Option A — script**

```bash
cd /path/to/demo-Project-enterprise
./scripts/bootstrap.sh
```

**Option B — manual**

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # edit location if you want
terraform init
terraform apply
terraform output
```

Copy `storage_account_name` from the output.

### Step 2 — Fill `backend.hcl`

Edit `environments/dev/backend.hcl`:

```hcl
resource_group_name  = "rg-tfstate-enterprise"
storage_account_name = "sttfstateXXXXXX"   # your real name
container_name       = "tfstate-dev"
key                  = "enterprise.tfstate"
```

### Step 3 — Init, plan, apply (`dev`)

**Option A — script (defaults to `dev`)**

```bash
./scripts/plan-env.sh
# creates tfplan inside environments/dev/
cd environments/dev
terraform apply tfplan
```

**Option B — full manual commands**

```bash
cd environments/dev
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

Expect **30–45+ minutes** if `enable_vpn = true` (VPN Gateway).

### Step 4 — Access via VPN

1. In Azure Portal → VPN Gateway → download the Point-to-Site client profile  
2. Install **Azure VPN Client**, import profile, connect (Entra ID or cert)  
3. Print the frontend URL:

```bash
cd environments/dev
terraform output frontend_hostname
```

4. Open `https://<that-hostname>` while connected to VPN  

Private DNS (`privatelink.azurewebsites.net`) resolves the App Service name to the Private Endpoint IP.

### Useful local commands

```bash
terraform fmt -recursive
./scripts/plan-env.sh              # plan dev
cd environments/dev && terraform destroy -var-file=terraform.tfvars   # careful
```

---

## 5. How the GitHub Actions pipeline works

### Workflows

| File | Trigger | What it does |
|------|---------|--------------|
| `.github/workflows/terraform-ci.yml` | PR / push to `main`/`master` (paths under modules, environments, bootstrap, workflows) + manual | `fmt` → validate modules → **plan `dev`** |
| `.github/workflows/terraform-apply.yml` | **Manual only** (`workflow_dispatch`) | Confirm you typed `dev` → plan → apply |

Learning path = **dev only**. Workflows include short comments on how to add more envs later.

### Secrets you must configure

| Secret | Purpose |
|--------|---------|
| `AZURE_CLIENT_ID` | App registration client ID (OIDC) |
| `AZURE_TENANT_ID` | Entra tenant |
| `AZURE_SUBSCRIPTION_ID` | Target subscription |
| `TF_STATE_RESOURCE_GROUP` | Usually `rg-tfstate-enterprise` |
| `TF_STATE_STORAGE_ACCOUNT` | Bootstrap storage account name |

Also create a GitHub **Environment** named `dev` (workflows reference `environment: dev`).

### OIDC (high level)

1. App Registration + federated credential for this repo (e.g. `repo:ORG/REPO:environment:dev`)  
2. Assign the service principal Contributor (or similar) on the subscription, and Storage Blob Data Contributor on the state account  
3. Workflows set `ARM_USE_OIDC=true` and use `azure/login@v2` with those secrets — **no long-lived client secret required**

### What CI does for `dev` backend

On each plan/apply job, the workflow **writes** `backend.hcl` from secrets (so you do not commit real storage names for CI):

```hcl
resource_group_name  = "<TF_STATE_RESOURCE_GROUP>"
storage_account_name = "<TF_STATE_STORAGE_ACCOUNT>"
container_name       = "tfstate-dev"
key                  = "enterprise.tfstate"
use_oidc             = true
```

Then:

```text
terraform init -backend-config=backend.hcl
terraform validate
terraform plan -var-file=terraform.tfvars ...
# apply workflow also: terraform apply tfplan
```

### Apply safety

`terraform-apply.yml` asks you to type `dev` in the `confirm` input. If it does not match, the job exits. That reduces accidental applies.

---

## Where to look next

| Goal | File |
|------|------|
| Short overview | [../README.md](../README.md) |
| Dev sizes / CIDRs | `environments/dev/terraform.tfvars` |
| Module wiring | `environments/dev/main.tf` |
| State bootstrap | `bootstrap/main.tf` |
| CI | `.github/workflows/terraform-ci.yml` |
| Apply | `.github/workflows/terraform-apply.yml` |

You only need **`dev`** to learn the whole pattern. Add more environments when the one-env path feels clear.
