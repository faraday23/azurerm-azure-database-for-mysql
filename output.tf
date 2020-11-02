output "resource_group_name" {
  description = "The name of the resource group in which resources are created"  
  value       = var.resource_group_name
}

output "administrator_login" {
  description = "The mysql instance login for the admin."
  sensitive   = true
  value       = local.administrator_login
}

output "administrator_password" {
  description = "The password for the admin account of the MySQL instance."
  sensitive   = true
  value       = local.administrator_password
}

output "name" {
  description = "The Name of the mysql instance."
  value       = azurerm_mysql_server.instance.name
}

output "id" {
  description = "The ID of the MySQL instance."
  value       = azurerm_mysql_server.instance.id
}

output "fqdn" {
  description = "The fully qualified domain name of the Azure MySQL Server" 
  value       = azurerm_mysql_server.instance.fqdn
}
