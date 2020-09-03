
output "storage_account_name" {
  value = azurerm_storage_account.sql_storage.name
}

output "primary_access_key" {
  value = azurerm_storage_account.sql_storage.primary_access_key
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.sql_storage.primary_blob_endpoint
}