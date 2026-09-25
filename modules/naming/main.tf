# Consistent Azure naming: <type>-<project>-<env>-<region>-<suffix>

locals {
  region_short = lookup({
    eastus        = "eus"
    eastus2       = "eus2"
    westus        = "wus"
    westus2       = "wus2"
    westus3       = "wus3"
    centralus     = "cus"
    northeurope   = "ne"
    westeurope    = "we"
    southeastasia = "sea"
    australiaeast = "ae"
    uksouth       = "uks"
    canadacentral = "cac"
  }, var.location, substr(replace(var.location, "/[^a-z0-9]/", ""), 0, 4))

  prefix = "${var.project}-${var.environment}"

  names = {
    resource_group = "rg-${local.prefix}-${local.region_short}"
    vnet           = "vnet-${local.prefix}-${local.region_short}"
    nsg_frontend   = "nsg-fe-${local.prefix}"
    nsg_backend    = "nsg-be-${local.prefix}"
    nsg_data       = "nsg-data-${local.prefix}"
    nsg_pe         = "nsg-pe-${local.prefix}"
    nsg_agw        = "nsg-agw-${local.prefix}"
    app_frontend   = "app-fe-${local.prefix}"
    app_backend    = "app-be-${local.prefix}"
    plan_frontend  = "asp-fe-${local.prefix}"
    plan_backend   = "asp-be-${local.prefix}"
    mysql          = "mysql-${local.prefix}"
    # Key Vault names: 3–24 chars, alphanumeric + hyphens only
    key_vault     = substr(replace("kv-${var.project}-${var.environment}-${local.region_short}", "/[^a-zA-Z0-9-]/", ""), 0, 24)
    log_analytics = "log-${local.prefix}"
    app_insights  = "appi-${local.prefix}"
    vpn_gateway   = "vpngw-${local.prefix}"
    public_ip_vpn = "pip-vpn-${local.prefix}"
    bastion       = "bas-${local.prefix}"
  }
}
