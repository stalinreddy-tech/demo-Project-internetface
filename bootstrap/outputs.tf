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

output "container_names" {
  description = "State containers per environment"
  value       = { for k, v in azurerm_storage_container.tfstate : k => v.name }
}

output "backend_config_hint" {
  description = "Copy storage_account_name into each environments/*/backend.hcl"
  value       = <<-EOT
    resource_group_name  = "${azurerm_resource_group.tfstate.name}"
    storage_account_name = "${azurerm_storage_account.tfstate.name}"
    # container_name = "tfstate-dev" | "tfstate-qa" | "tfstate-prod"
    key                  = "internetface.tfstate"
  EOT
}
