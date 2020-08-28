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
  value       = azurerm_mysql_server.primary.name
  description = "The Name of the mysql instance."
}

output "name_replica" {
  value       = azurerm_mysql_server.replica.name
  description = "The Name of the mysql instance."
}

output "id" {
  value       = azurerm_mysql_server.primary.id
  description = "The ID of the mysql instance."
}

output "id_replica" {
  value       = azurerm_mysql_server.replica.id
  description = "The ID of the mysql instance."
}

output "fqdn" {
  value       = azurerm_mysql_server.primary.fqdn
  description = "The FQDN of the mysql instance."
}

output "fqdn_replica" {
  value       = azurerm_mysql_server.replica.fqdn
  description = "The FQDN of the mysql instance."
}