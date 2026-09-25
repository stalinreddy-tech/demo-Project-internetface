# =============================================================================
# VPN Module — Point-to-Site (P2S) for internal users
# Why: Users connect over VPN into the VNet and reach the frontend Private Endpoint.
#      The app never needs a public inbound path.
# =============================================================================

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

resource "azurerm_public_ip" "vpn" {
  name                = var.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

locals {
  use_aad = var.aad_tenant_id != null && var.aad_tenant_id != ""
}

resource "azurerm_virtual_network_gateway" "vpn" {
  name                = var.vpn_gateway_name
  location            = var.location
  resource_group_name = var.resource_group_name

  type     = "Vpn"
  vpn_type = "RouteBased"
  sku      = var.vpn_sku

  generation = startswith(var.vpn_sku, "VpnGw2") || startswith(var.vpn_sku, "VpnGw3") || startswith(var.vpn_sku, "VpnGw4") || startswith(var.vpn_sku, "VpnGw5") ? "Generation2" : "Generation1"

  active_active = false
  enable_bgp    = false

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }

  vpn_client_configuration {
    address_space        = var.vpn_client_address_space
    vpn_client_protocols = local.use_aad ? ["OpenVPN"] : ["IkeV2", "OpenVPN"]
    vpn_auth_types       = local.use_aad ? ["AAD"] : ["Certificate"]

    aad_tenant   = local.use_aad ? "https://login.microsoftonline.com/${var.aad_tenant_id}/" : null
    aad_audience = local.use_aad ? var.aad_audience : null
    aad_issuer   = local.use_aad ? "https://sts.windows.net/${var.aad_tenant_id}/" : null

    dynamic "root_certificate" {
      for_each = !local.use_aad && var.root_certificate_public_cert_data != null ? [1] : []
      content {
        name             = "P2SRootCert"
        public_cert_data = var.root_certificate_public_cert_data
      }
    }
  }

  tags = var.tags

  timeouts {
    create = "90m"
    update = "90m"
    delete = "90m"
  }
}
