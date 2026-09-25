variable "name" {
  description = "Private endpoint name"
  type        = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  description = "Subnet ID for private endpoints (no App Service delegation)"
  type        = string
}

variable "target_resource_id" {
  description = "Resource ID of the PaaS service to privatize"
  type        = string
}

variable "subresource_names" {
  description = "Private Link subresource names (e.g. sites, vault)"
  type        = list(string)
}

variable "private_dns_zone_ids" {
  description = "Private DNS zones to auto-register A records"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
