variable "project" {
  description = "Short project name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name: dev | qa | prod"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}
