output "id" {
  description = "Web App resource ID"
  value       = azurerm_linux_web_app.this.id
}

output "name" {
  description = "Web App name"
  value       = azurerm_linux_web_app.this.name
}

output "default_hostname" {
  description = "Default hostname (resolves privately via Private DNS when PE is attached)"
  value       = azurerm_linux_web_app.this.default_hostname
}

output "principal_id" {
  description = "System-assigned managed identity principal ID"
  value       = azurerm_linux_web_app.this.identity[0].principal_id
}

output "service_plan_id" {
  description = "App Service Plan ID"
  value       = azurerm_service_plan.this.id
}

output "outbound_ip_addresses" {
  description = "Outbound IPs (prefer VNet integration path for private tiers)"
  value       = azurerm_linux_web_app.this.outbound_ip_addresses
}
