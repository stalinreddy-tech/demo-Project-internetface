# =============================================================================
# App Service Module (Linux) — public web or API app
# Why:
#  - public_network_access_enabled = true → internet users / mobile can reach the app
#  - VNet integration → outbound into private subnets (API → MySQL, Key Vault PE)
#  - ip_restriction (optional) → extra allow/deny rules when needed
# =============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

resource "azurerm_service_plan" "this" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "this" {
  name                = var.app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.this.id
  https_only          = true

  public_network_access_enabled = var.public_network_access_enabled
  virtual_network_subnet_id     = var.vnet_integration_subnet_id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on                         = var.sku_name != "F1" && var.sku_name != "D1"
    ftps_state                        = "Disabled"
    minimum_tls_version               = "1.2"
    vnet_route_all_enabled            = var.vnet_integration_subnet_id != null
    health_check_path                 = var.health_check_path
    health_check_eviction_time_in_min = var.health_check_path != null ? 5 : null

    application_stack {
      node_version = var.node_version
    }

    # With no rules, Allow = open to internet (when public_network_access_enabled = true)
    ip_restriction_default_action = length(var.ip_restrictions) > 0 ? "Deny" : "Allow"

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions
      content {
        name                      = ip_restriction.value.name
        priority                  = ip_restriction.value.priority
        action                    = ip_restriction.value.action
        ip_address                = try(ip_restriction.value.ip_address, null)
        virtual_network_subnet_id = try(ip_restriction.value.virtual_network_subnet_id, null)
        service_tag               = try(ip_restriction.value.service_tag, null)
        # Do not set headers = null — azurerm requires list(object) or omit the attribute.
      }
    }
  }

  app_settings = merge(
    {
      WEBSITE_RUN_FROM_PACKAGE                   = "1"
      APPLICATIONINSIGHTS_CONNECTION_STRING      = var.app_insights_connection_string
      ApplicationInsightsAgent_EXTENSION_VERSION = "~3"
    },
    var.vnet_integration_subnet_id != null ? {
      WEBSITE_DNS_SERVER     = "168.63.129.16"
      WEBSITE_VNET_ROUTE_ALL = "1"
    } : {},
    var.app_settings
  )

  dynamic "connection_string" {
    for_each = var.connection_strings
    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # App settings often managed by deploy pipelines / Key Vault references after first apply
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}
