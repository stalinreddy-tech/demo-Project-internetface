output "id" {
  description = "Key Vault resource ID"
  value       = azurerm_key_vault.this.id
}

output "name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.this.name
}

output "uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.this.vault_uri
}

output "secret_ids" {
  description = "Map of secret names to versionless IDs (for Key Vault references)"
  value       = { for k, v in azurerm_key_vault_secret.secrets : k => v.versionless_id }
  sensitive   = true
}
