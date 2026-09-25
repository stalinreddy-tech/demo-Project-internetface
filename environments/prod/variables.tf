variable "project" {
  type    = string
  default = "iface"
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
    api               = string
    mysql             = string
    private_endpoints = string
  })
}

variable "web_sku" {
  type    = string
  default = "B1"
}

variable "api_sku" {
  type    = string
  default = "B1"
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
  description = "Allow Key Vault management from internet (local/CI apply). API uses VNet + PE for secrets."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
