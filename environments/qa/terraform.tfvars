# QA — internet-facing

project     = "iface"
environment = "qa"
location    = "eastus"

address_space = ["10.50.0.0/16"]

subnet_cidrs = {
  api               = "10.50.1.0/24"
  mysql             = "10.50.2.0/24"
  private_endpoints = "10.50.3.0/24"
}

web_sku   = "B1"
api_sku   = "B1"
mysql_sku = "GP_Standard_D2ds_v4"

mysql_storage_gb           = 64
mysql_ha_mode              = "Disabled"
mysql_geo_redundant_backup = false
log_retention_days         = 60
key_vault_purge_protection = false

tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
  Exposure   = "internet-facing"
}
