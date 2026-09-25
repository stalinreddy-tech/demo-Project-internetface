output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet IDs by role"
  value = {
    frontend          = azurerm_subnet.frontend.id
    backend           = azurerm_subnet.backend.id
    mysql             = azurerm_subnet.mysql.id
    private_endpoints = azurerm_subnet.private_endpoints.id
    gateway           = azurerm_subnet.gateway.id
    bastion           = try(azurerm_subnet.bastion[0].id, null)
  }
}

output "subnet_cidrs" {
  description = "Subnet CIDRs (for NSG / access restriction references)"
  value       = var.subnet_cidrs
}

output "private_dns_zone_ids" {
  description = "Private DNS zone IDs"
  value = {
    appservice     = azurerm_private_dns_zone.appservice.id
    mysql          = azurerm_private_dns_zone.mysql.id
    keyvault       = azurerm_private_dns_zone.keyvault.id
    mysql_flexible = azurerm_private_dns_zone.mysql_flexible.id
  }
}

output "private_dns_zone_names" {
  description = "Private DNS zone names"
  value = {
    appservice     = azurerm_private_dns_zone.appservice.name
    mysql          = azurerm_private_dns_zone.mysql.name
    keyvault       = azurerm_private_dns_zone.keyvault.name
    mysql_flexible = azurerm_private_dns_zone.mysql_flexible.name
  }
}
