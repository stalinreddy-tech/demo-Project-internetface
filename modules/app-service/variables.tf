variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "app_name" {
  description = "Globally unique App Service name"
  type        = string
}

variable "app_service_plan_name" {
  type = string
}

variable "sku_name" {
  description = "App Service Plan SKU (B1 for cheap public demos; P0v3/P1v3+ for higher load)"
  type        = string
  default     = "B1"
}

variable "public_network_access_enabled" {
  description = "Allow inbound from the public internet (required for internet-facing web/API)"
  type        = bool
  default     = true
}

variable "node_version" {
  description = "Node.js runtime version on Linux App Service"
  type        = string
  default     = "20-lts"
}

variable "vnet_integration_subnet_id" {
  description = "Delegated subnet for regional VNet integration (outbound). Null = no VNet integration."
  type        = string
  default     = null
}

variable "health_check_path" {
  type    = string
  default = "/health"
}

variable "app_settings" {
  type    = map(string)
  default = {}
}

variable "connection_strings" {
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default   = []
  sensitive = true
}

variable "ip_restrictions" {
  description = "Optional access restriction rules. Empty + public access = open to internet (HTTPS)."
  type = list(object({
    name                      = string
    priority                  = number
    action                    = string
    ip_address                = optional(string)
    virtual_network_subnet_id = optional(string)
    service_tag               = optional(string)
  }))
  default = []
}

variable "app_insights_connection_string" {
  type      = string
  default   = ""
  sensitive = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
