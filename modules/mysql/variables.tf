variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "server_name" {
  description = "MySQL Flexible Server name (globally unique)"
  type        = string
}

variable "administrator_login" {
  type    = string
  default = "mysqladmin"
}

variable "administrator_password" {
  description = "Optional override; random password generated if null"
  type        = string
  default     = null
  sensitive   = true
}

variable "sku_name" {
  description = "e.g. B_Standard_B1ms (dev), GP_Standard_D2ds_v4 (prod)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "mysql_version" {
  type    = string
  default = "8.0.21"
}

variable "zone" {
  type    = string
  default = "1"
}

variable "standby_zone" {
  type    = string
  default = "2"
}

variable "delegated_subnet_id" {
  description = "Subnet delegated to Microsoft.DBforMySQL/flexibleServers"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for MySQL Flexible Server"
  type        = string
}

variable "database_name" {
  type    = string
  default = "appdb"
}

variable "storage_size_gb" {
  type    = number
  default = 32
}

variable "iops" {
  type    = number
  default = 360
}

variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "geo_redundant_backup_enabled" {
  type    = bool
  default = false
}

variable "high_availability_mode" {
  description = "Disabled | SameZone | ZoneRedundant (ZoneRedundant needs GP/MO SKU)"
  type        = string
  default     = "Disabled"
}

variable "tags" {
  type    = map(string)
  default = {}
}
