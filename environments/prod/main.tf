# =============================================================================
# Internet-facing 3-tier (Azure infra demo — no real frontend apps)
#
#   Public internet / mobile → Web App Service (public)
#   Public internet / mobile / web → API App Service (public)
#   API (VNet integration) → MySQL (private; API subnet only)
# =============================================================================

locals {
  common_tags = merge(var.tags, {
    Project      = var.project
    Environment  = var.environment
    ManagedBy    = "terraform"
    Architecture = "internet-facing-3tier"
  })

  mysql_dns_zone_name = "${var.project}-${var.environment}.mysql.database.azure.com"
  name_suffix         = random_string.suffix.result
  web_app_name        = "${module.naming.names.app_web}-${local.name_suffix}"
  api_app_name        = "${module.naming.names.app_api}-${local.name_suffix}"
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

  nsg_names = {
    api               = module.naming.names.nsg_api
    data              = module.naming.names.nsg_data
    private_endpoints = module.naming.names.nsg_pe
  }

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
  allowed_subnet_ids            = [module.networking.subnet_ids.api]

  secrets = {
    mysql-admin-password = module.mysql.administrator_password
    mysql-connection     = module.mysql.connection_string
  }

  secret_reader_principal_ids = []

  tags = local.common_tags

  depends_on = [module.mysql]
}

# Web — PUBLIC. No DB settings.
module "web" {
  source = "../../modules/app-service"

  resource_group_name            = azurerm_resource_group.this.name
  location                       = var.location
  app_name                       = local.web_app_name
  app_service_plan_name          = module.naming.names.plan_web
  sku_name                       = var.web_sku
  node_version                   = "20-lts"
  public_network_access_enabled  = true
  vnet_integration_subnet_id     = null
  health_check_path              = "/health"
  app_insights_connection_string = module.monitoring.application_insights_connection_string
  ip_restrictions                = []

  app_settings = {
    APP_ROLE                     = "frontend"
    API_URL                      = "https://${local.api_app_name}.azurewebsites.net"
    WEBSITE_NODE_DEFAULT_VERSION = "~20"
  }

  tags = local.common_tags
}

# API — PUBLIC to web + mobile. Only tier with DB + VNet → MySQL.
module "api" {
  source = "../../modules/app-service"

  resource_group_name            = azurerm_resource_group.this.name
  location                       = var.location
  app_name                       = local.api_app_name
  app_service_plan_name          = module.naming.names.plan_api
  sku_name                       = var.api_sku
  node_version                   = "20-lts"
  public_network_access_enabled  = true
  vnet_integration_subnet_id     = module.networking.subnet_ids.api
  health_check_path              = "/health"
  app_insights_connection_string = module.monitoring.application_insights_connection_string
  ip_restrictions                = []

  app_settings = {
    APP_ROLE    = "api"
    DB_HOST     = module.mysql.fqdn
    DB_NAME     = module.mysql.database_name
    DB_USER     = module.mysql.administrator_login
    DB_SSL      = "true"
    DB_PASSWORD = "@Microsoft.KeyVault(SecretUri=${module.key_vault.uri}secrets/mysql-admin-password/)"
  }

  tags = local.common_tags

  depends_on = [module.mysql, module.key_vault]
}

resource "azurerm_role_assignment" "api_kv_secrets" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.api.principal_id
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
