# PROD — internet-facing

project     = "iface"
environment = "prod"
location    = "eastus"

address_space = ["10.60.0.0/16"]

subnet_cidrs = {
  api               = "10.60.1.0/24"
  mysql             = "10.60.2.0/24"
  private_endpoints = "10.60.3.0/24"
}

web_sku   = "P0v3"
api_sku   = "P0v3"
mysql_sku = "GP_Standard_D2ds_v4"

mysql_storage_gb           = 128
mysql_ha_mode              = "ZoneRedundant"
mysql_geo_redundant_backup = true
log_retention_days         = 90
key_vault_purge_protection = true

tags = {
  CostCenter  = "engineering"
  Owner       = "platform-team"
  Exposure    = "internet-facing"
  Criticality = "high"
}
