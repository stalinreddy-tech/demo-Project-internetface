output "resource_group_name" {
  description = "Resource group holding Terraform state storage"
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Storage account name for Terraform backends"
  value       = azurerm_storage_account.tfstate.name
}

output "storage_account_id" {
  description = "Storage account resource ID"
  value       = azurerm_storage_account.tfstate.id
}

output "container_name" {
  description = "State container for the dev environment"
  value       = azurerm_storage_container.tfstate_dev.name
}

output "backend_config_hint" {
  description = "Copy these values into environments/dev/backend.hcl"
  value       = <<-EOT
    resource_group_name  = "${azurerm_resource_group.tfstate.name}"
    storage_account_name = "${azurerm_storage_account.tfstate.name}"
    container_name       = "${azurerm_storage_container.tfstate_dev.name}"
    key                  = "enterprise.tfstate"
  EOT
}
