# Environments

Same `main.tf` / modules. Differs by `terraform.tfvars` + `backend.hcl` container.

| Env | VNet | State container |
|-----|------|-----------------|
| dev | `10.40.0.0/16` | `tfstate-dev` |
| qa | `10.50.0.0/16` | `tfstate-qa` |
| prod | `10.60.0.0/16` | `tfstate-prod` |

Blob key everywhere: `internetface.tfstate`

```bash
./scripts/bootstrap.sh
cd environments/qa
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

Or: **Actions → Terraform CI** / **Terraform Apply** (manual `workflow_dispatch` only).
