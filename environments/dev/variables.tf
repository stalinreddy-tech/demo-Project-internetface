variable "project" {
  description = "Short project slug used in names"
  type        = string
  default     = "ente"
}

variable "environment" {
  type = string
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "address_space" {
  type = list(string)
}

variable "subnet_cidrs" {
  type = object({
    frontend          = string
    backend           = string
    mysql             = string
    private_endpoints = string
    gateway           = string
    bastion           = string
  })
}

variable "vpn_client_address_space" {
  type = list(string)
}

variable "vpn_sku" {
  type    = string
  default = "VpnGw1"
}

variable "enable_vpn" {
  description = "Deploy VPN Gateway (costly; enable when P2S access is needed)"
  type        = bool
  default     = true
}

variable "aad_tenant_id" {
  description = "Entra ID tenant for Azure AD P2S. Null = skip AAD auth (set cert via root_certificate_public_cert_data)."
  type        = string
  default     = null
}

variable "root_certificate_public_cert_data" {
  type      = string
  default   = null
  sensitive = true
}

variable "frontend_sku" {
  type    = string
  default = "P0v3"
}

variable "backend_sku" {
  type    = string
  default = "P0v3"
}

variable "mysql_sku" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "mysql_storage_gb" {
  type    = number
  default = 32
}

variable "mysql_ha_mode" {
  type    = string
  default = "Disabled"
}

variable "mysql_geo_redundant_backup" {
  type    = bool
  default = false
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "key_vault_purge_protection" {
  type    = bool
  default = false
}

variable "key_vault_public_network_access" {
  description = "Allow Key Vault management plane from internet (needed for local/CI apply). Apps still use Private Endpoint. Set false only when Terraform runs inside the VNet."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
