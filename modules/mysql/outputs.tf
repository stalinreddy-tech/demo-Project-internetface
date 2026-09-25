output "id" {
  description = "MySQL Flexible Server ID"
  value       = azurerm_mysql_flexible_server.this.id
}

output "name" {
  description = "Server name"
  value       = azurerm_mysql_flexible_server.this.name
}

output "fqdn" {
  description = "Private FQDN of the MySQL server"
  value       = azurerm_mysql_flexible_server.this.fqdn
}

output "database_name" {
  description = "Application database name"
  value       = azurerm_mysql_flexible_database.app.name
}

output "administrator_login" {
  description = "Admin login"
  value       = azurerm_mysql_flexible_server.this.administrator_login
}

output "administrator_password" {
  description = "Admin password (store in Key Vault; do not log)"
  value       = var.administrator_password != null ? var.administrator_password : random_password.admin.result
  sensitive   = true
}

output "connection_string" {
  description = "MySQL connection string for the backend app"
  value       = "Server=${azurerm_mysql_flexible_server.this.fqdn};Port=3306;Database=${azurerm_mysql_flexible_database.app.name};Uid=${azurerm_mysql_flexible_server.this.administrator_login};Pwd=${var.administrator_password != null ? var.administrator_password : random_password.admin.result};SslMode=Required;"
  sensitive   = true
}
