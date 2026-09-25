# =============================================================================
# DEV environment values — smaller SKUs, shorter retention, VPN enabled
# =============================================================================

project     = "ente"
environment = "dev"
location    = "eastus"

address_space = ["10.10.0.0/16"]

subnet_cidrs = {
  frontend          = "10.10.1.0/24"
  backend           = "10.10.2.0/24"
  mysql             = "10.10.3.0/24"
  private_endpoints = "10.10.4.0/24"
  gateway           = "10.10.5.0/27"
  bastion           = "10.10.6.0/26"
}

vpn_client_address_space = ["172.16.10.0/24"]
enable_vpn               = true
vpn_sku                  = "VpnGw1"

# Set via TF_VAR_aad_tenant_id or CI secrets for Azure AD P2S
# aad_tenant_id = "00000000-0000-0000-0000-000000000000"

frontend_sku = "P0v3"
backend_sku  = "P0v3"
mysql_sku    = "B_Standard_B1ms"

mysql_storage_gb           = 32
mysql_ha_mode              = "Disabled"
mysql_geo_redundant_backup = false
log_retention_days         = 30
key_vault_purge_protection = false

tags = {
  CostCenter = "engineering"
  Owner      = "platform-team"
}
