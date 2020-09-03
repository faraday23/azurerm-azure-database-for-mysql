output "administrator_login" {
  value       = var.administrator_login
  sensitive   = true
  description = "The MySQL instance login for the admin."
}

output "password" {
  value       = random_password.login_password.result
  sensitive   = true
  description = "The MySQL instance password for the admin."
}

output "name" {
  value       = azurerm_mysql_server.server.name
  description = "The Name of the mysql instance."
}

output "id" {
  value       = azurerm_mysql_server.server.id
  description = "The ID of the mysql instance."
}

output "fqdn" {
  value       = azurerm_mysql_server.server.fqdn
  description = "The FQDN of the mysql instance."
}
