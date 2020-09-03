# Configure name of storage account
resource "random_string" "storage_name" {
    length  = 8
    upper   = false
    lower   = true
    number  = true
    special = false
}

# Manages an Azure Storage Account for Threat detection policy analytics.
resource "azurerm_storage_account" "sql_storage" {
  name                     = "stor${random_string.storage_name.result}${var.db_id}"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = var.tags
}
