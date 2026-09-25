variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vpn_gateway_name" {
  type = string
}

variable "public_ip_name" {
  type = string
}

variable "gateway_subnet_id" {
  description = "ID of the GatewaySubnet"
  type        = string
}

variable "vpn_sku" {
  description = "VPN Gateway SKU (VpnGw1 for non-prod, VpnGw2+ for prod HA)"
  type        = string
  default     = "VpnGw1"
}

variable "vpn_client_address_space" {
  description = "Address pool assigned to P2S VPN clients (must not overlap VNet)"
  type        = list(string)
  default     = ["172.16.0.0/24"]
}

variable "aad_tenant_id" {
  description = "Entra ID tenant ID for Azure AD P2S auth. Null = certificate auth instead."
  type        = string
  default     = null
}

variable "aad_audience" {
  description = "Azure VPN Client app audience (public Azure: 41b23e61-6c1e-4545-b367-cd054e0ed4b4)"
  type        = string
  default     = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
}

variable "root_certificate_public_cert_data" {
  description = "Base64 public cert data for certificate-based P2S (when aad_tenant_id is null)"
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
