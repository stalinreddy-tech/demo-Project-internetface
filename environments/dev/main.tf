# =============================================================================
# Environment root — wires enterprise modules into a private 3-tier stack
# Traffic: VPN users → Frontend PE → (proxy) Backend PE → MySQL (VNet)
# =============================================================================

locals {
  common_tags = merge(var.tags, {
    Project      = var.project
    Environment  = var.environment
    ManagedBy    = "terraform"
    Architecture = "private-3tier"
  })

  mysql_dns_zone_name = "${var.project}-${var.environment}.mysql.database.azure.com"
  name_suffix         = random_string.suffix.result
  frontend_app_name   = "${module.naming.names.app_frontend}-${local.name_suffix}"
  backend_app_name    = "${module.naming.names.app_backend}-${local.name_suffix}"
  mysql_server_name   = "${module.naming.names.mysql}${local.name_suffix}"
  key_vault_name      = substr("${module.naming.names.key_vault}${local.name_suffix}", 0, 24)
}

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

module "naming" {
  source = "../../modules/naming"

  project     = var.project
  environment = var.environment
  location    = var.location
}

resource "azurerm_resource_group" "this" {
  name     = module.naming.names.resource_group
  location = var.location
  tags     = local.common_tags
}

module "networking" {
  source = "../../modules/networking"

  resource_group_name         = azurerm_resource_group.this.name
  location                    = var.location
  vnet_name                   = module.naming.names.vnet
  address_space               = var.address_space
  subnet_cidrs                = var.subnet_cidrs
  mysql_private_dns_zone_name = local.mysql_dns_zone_name
  enable_bastion_subnet       = false

  nsg_names = {
    frontend          = module.naming.names.nsg_frontend
    backend           = module.naming.names.nsg_backend
    data              = module.naming.names.nsg_data
    private_endpoints = module.naming.names.nsg_pe
  }

  tags = local.common_tags
}

module "vpn" {
  source = "../../modules/vpn"
  count  = var.enable_vpn ? 1 : 0

  resource_group_name               = azurerm_resource_group.this.name
  location                          = var.location
  vpn_gateway_name                  = module.naming.names.vpn_gateway
  public_ip_name                    = module.naming.names.public_ip_vpn
  gateway_subnet_id                 = module.networking.subnet_ids.gateway
  vpn_sku                           = var.vpn_sku
  vpn_client_address_space          = var.vpn_client_address_space
  aad_tenant_id                     = var.aad_tenant_id
  root_certificate_public_cert_data = var.root_certificate_public_cert_data

  tags = local.common_tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  log_analytics_name  = module.naming.names.log_analytics
  app_insights_name   = module.naming.names.app_insights
  retention_in_days   = var.log_retention_days
  tags                = local.common_tags
}

module "mysql" {
  source = "../../modules/mysql"

  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  server_name                  = local.mysql_server_name
  delegated_subnet_id          = module.networking.subnet_ids.mysql
  private_dns_zone_id          = module.networking.private_dns_zone_ids.mysql_flexible
  sku_name                     = var.mysql_sku
  storage_size_gb              = var.mysql_storage_gb
  high_availability_mode       = var.mysql_ha_mode
  geo_redundant_backup_enabled = var.mysql_geo_redundant_backup
  database_name                = "appdb"
  tags                         = local.common_tags

  depends_on = [module.networking]
}

module "key_vault" {
  source = "../../modules/key-vault"

  name                          = local.key_vault_name
  location                      = var.location
  resource_group_name           = azurerm_resource_group.this.name
  purge_protection_enabled      = var.key_vault_purge_protection
  public_network_access_enabled = var.key_vault_public_network_access
  allowed_subnet_ids            = []

  secrets = {
    mysql-admin-password = module.mysql.administrator_password
    mysql-connection     = module.mysql.connection_string
  }

  # Role assignments for app identities are created below (avoids circular deps)
  secret_reader_principal_ids = []

  tags = local.common_tags

  depends_on = [module.mysql]
}

module "frontend" {
  source = "../../modules/app-service"

  resource_group_name            = azurerm_resource_group.this.name
  location                       = var.location
  app_name                       = local.frontend_app_name
  app_service_plan_name          = module.naming.names.plan_frontend
  sku_name                       = var.frontend_sku
  node_version                   = "20-lts"
  vnet_integration_subnet_id     = module.networking.subnet_ids.frontend
  health_check_path              = "/health"
  app_insights_connection_string = module.monitoring.application_insights_connection_string
  ip_restrictions                = []

  app_settings = {
    APP_ROLE                     = "frontend"
    BACKEND_URL                  = "https://${local.backend_app_name}.azurewebsites.net"
    WEBSITE_NODE_DEFAULT_VERSION = "~20"
  }

  tags = local.common_tags
}

module "backend" {
  source = "../../modules/app-service"

  resource_group_name            = azurerm_resource_group.this.name
  location                       = var.location
  app_name                       = local.backend_app_name
  app_service_plan_name          = module.naming.names.plan_backend
  sku_name                       = var.backend_sku
  node_version                   = "20-lts"
  vnet_integration_subnet_id     = module.networking.subnet_ids.backend
  health_check_path              = "/health"
  app_insights_connection_string = module.monitoring.application_insights_connection_string

  ip_restrictions = [
    {
      name                      = "AllowFrontendSubnetOnly"
      priority                  = 100
      action                    = "Allow"
      virtual_network_subnet_id = module.networking.subnet_ids.frontend
    }
  ]

  app_settings = {
    APP_ROLE    = "backend"
    DB_HOST     = module.mysql.fqdn
    DB_NAME     = module.mysql.database_name
    DB_USER     = module.mysql.administrator_login
    DB_SSL      = "true"
    DB_PASSWORD = "@Microsoft.KeyVault(SecretUri=${module.key_vault.uri}secrets/mysql-admin-password/)"
  }

  tags = local.common_tags

  depends_on = [module.mysql, module.key_vault]
}

resource "azurerm_role_assignment" "frontend_kv_secrets" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.frontend.principal_id
}

resource "azurerm_role_assignment" "backend_kv_secrets" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.backend.principal_id
}

module "pe_frontend" {
  source = "../../modules/private-endpoint"

  name                 = "pe-${module.frontend.name}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  subnet_id            = module.networking.subnet_ids.private_endpoints
  target_resource_id   = module.frontend.id
  subresource_names    = ["sites"]
  private_dns_zone_ids = [module.networking.private_dns_zone_ids.appservice]
  tags                 = local.common_tags
}

module "pe_backend" {
  source = "../../modules/private-endpoint"

  name                 = "pe-${module.backend.name}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  subnet_id            = module.networking.subnet_ids.private_endpoints
  target_resource_id   = module.backend.id
  subresource_names    = ["sites"]
  private_dns_zone_ids = [module.networking.private_dns_zone_ids.appservice]
  tags                 = local.common_tags
}

module "pe_key_vault" {
  source = "../../modules/private-endpoint"

  name                 = "pe-${module.key_vault.name}"
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  subnet_id            = module.networking.subnet_ids.private_endpoints
  target_resource_id   = module.key_vault.id
  subresource_names    = ["vault"]
  private_dns_zone_ids = [module.networking.private_dns_zone_ids.keyvault]
  tags                 = local.common_tags
}
