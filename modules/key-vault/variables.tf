variable "name" {
  description = "Key Vault name (3-24 chars, alphanumeric and hyphens)"
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "standard"
}

variable "purge_protection_enabled" {
  description = "Enable for prod to prevent purge of soft-deleted vaults"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Set false after Private Endpoint is in place (bootstrap may need true briefly)"
  type        = bool
  default     = false
}

variable "allowed_ip_rules" {
  type    = list(string)
  default = []
}

variable "allowed_subnet_ids" {
  type    = list(string)
  default = []
}

variable "secrets" {
  description = "Map of secret name → value (values are stored in Terraform state; treat state as confidential)"
  type        = map(string)
  default     = {}
}

variable "secret_reader_principal_ids" {
  description = "Managed identity object IDs that may read secrets"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
