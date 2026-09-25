variable "resource_group_name" {
  description = "Resource group for networking resources"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
}

variable "address_space" {
  description = "VNet address space CIDRs"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_cidrs" {
  description = "CIDR for each subnet role"
  type = object({
    frontend          = string
    backend           = string
    mysql             = string
    private_endpoints = string
    gateway           = string
    bastion           = string
  })
}

variable "nsg_names" {
  description = "NSG names per tier"
  type = object({
    frontend          = string
    backend           = string
    data              = string
    private_endpoints = string
  })
}

variable "mysql_private_dns_zone_name" {
  description = "Private DNS zone name for MySQL Flexible Server (must be unique globally for the org pattern)"
  type        = string
  default     = "privatelink.mysql.database.azure.com"
}

variable "enable_bastion_subnet" {
  description = "Create AzureBastionSubnet (Bastion resource itself is optional elsewhere)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
