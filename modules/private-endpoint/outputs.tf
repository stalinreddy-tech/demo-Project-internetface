output "id" {
  description = "Private endpoint ID"
  value       = azurerm_private_endpoint.this.id
}

output "private_ip_address" {
  description = "Private IP allocated to the endpoint"
  value       = try(azurerm_private_endpoint.this.private_service_connection[0].private_ip_address, null)
}
