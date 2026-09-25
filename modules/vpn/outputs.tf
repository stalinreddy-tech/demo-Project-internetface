output "vpn_gateway_id" {
  description = "VPN Gateway resource ID"
  value       = azurerm_virtual_network_gateway.vpn.id
}

output "vpn_gateway_name" {
  description = "VPN Gateway name"
  value       = azurerm_virtual_network_gateway.vpn.name
}

output "public_ip_address" {
  description = "Public IP used by the VPN Gateway (control plane only; app traffic stays private)"
  value       = azurerm_public_ip.vpn.ip_address
}
