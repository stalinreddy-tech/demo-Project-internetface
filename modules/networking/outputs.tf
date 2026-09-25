output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  value = {
    api               = azurerm_subnet.api.id
    mysql             = azurerm_subnet.mysql.id
    private_endpoints = azurerm_subnet.private_endpoints.id
  }
}

output "subnet_cidrs" {
  value = var.subnet_cidrs
}

output "private_dns_zone_ids" {
  value = {
    mysql          = azurerm_private_dns_zone.mysql.id
    keyvault       = azurerm_private_dns_zone.keyvault.id
    mysql_flexible = azurerm_private_dns_zone.mysql_flexible.id
  }
}

output "private_dns_zone_names" {
  value = {
    mysql          = azurerm_private_dns_zone.mysql.name
    keyvault       = azurerm_private_dns_zone.keyvault.name
    mysql_flexible = azurerm_private_dns_zone.mysql_flexible.name
  }
}
