output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "frontend_url" {
  description = "Public HTTPS URL for the web app (no VPN)"
  value       = "https://${module.web.default_hostname}"
}

output "api_url" {
  description = "Public HTTPS URL for the API (web + mobile)"
  value       = "https://${module.api.default_hostname}"
}

output "frontend_hostname" {
  value = module.web.default_hostname
}

output "api_hostname" {
  value = module.api.default_hostname
}

output "mysql_fqdn" {
  description = "Private MySQL FQDN (API VNet integration only)"
  value       = module.mysql.fqdn
}

output "key_vault_uri" {
  value = module.key_vault.uri
}

output "vnet_id" {
  value = module.networking.vnet_id
}

output "application_insights_connection_string" {
  value     = module.monitoring.application_insights_connection_string
  sensitive = true
}
