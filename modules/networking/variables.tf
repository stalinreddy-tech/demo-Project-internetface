variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "address_space" {
  type    = list(string)
  default = ["10.0.0.0/16"]
}

variable "subnet_cidrs" {
  description = "CIDR for API, MySQL, and private-endpoint subnets"
  type = object({
    api               = string
    mysql             = string
    private_endpoints = string
  })
}

variable "nsg_names" {
  type = object({
    api               = string
    data              = string
    private_endpoints = string
  })
}

variable "mysql_private_dns_zone_name" {
  description = "Private DNS zone name for MySQL Flexible Server"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
