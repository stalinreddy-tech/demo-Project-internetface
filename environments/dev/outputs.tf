output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "frontend_hostname" {
  description = "Frontend App Service hostname (access via VPN + Private DNS)"
  value       = module.frontend.default_hostname
}

output "backend_hostname" {
  description = "Backend App Service hostname (only reachable from frontend subnet)"
  value       = module.backend.default_hostname
}

output "mysql_fqdn" {
  description = "Private MySQL FQDN"
  value       = module.mysql.fqdn
}

output "key_vault_uri" {
  value = module.key_vault.uri
}

output "vpn_public_ip" {
  description = "VPN Gateway public IP (for Azure VPN Client profile download only)"
  value       = try(module.vpn[0].public_ip_address, null)
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "application_insights_connection_string" {
  value     = module.monitoring.application_insights_connection_string
  sensitive = true
}
