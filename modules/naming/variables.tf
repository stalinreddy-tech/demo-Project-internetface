variable "project" {
  description = "Short project name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (this learning repo uses: dev). Add more later as needed."
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}
