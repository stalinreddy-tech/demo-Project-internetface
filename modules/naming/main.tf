# Consistent Azure naming: <type>-<project>-<env>-<region>

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
    nsg_api        = "nsg-api-${local.prefix}"
    nsg_data       = "nsg-data-${local.prefix}"
    nsg_pe         = "nsg-pe-${local.prefix}"
    app_web        = "app-web-${local.prefix}"
    app_api        = "app-api-${local.prefix}"
    plan_web       = "asp-web-${local.prefix}"
    plan_api       = "asp-api-${local.prefix}"
    mysql          = "mysql-${local.prefix}"
    key_vault      = substr(replace("kv-${var.project}-${var.environment}-${local.region_short}", "/[^a-zA-Z0-9-]/", ""), 0, 24)
    log_analytics  = "log-${local.prefix}"
    app_insights   = "appi-${local.prefix}"
  }
}
