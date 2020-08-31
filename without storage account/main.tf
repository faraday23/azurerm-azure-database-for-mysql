# Configure azure provider
provider "azurerm" {
  version = ">= 2.24.0"
  features {}
}

# creates random password for mysql admin account
resource "random_password" "login_password" {
  length  = 24
  special = true
}

# Configure name of storage account
resource "random_string" "storage_name" {
    length  = 8
    upper   = false
    lower   = true
    number  = true
    special = false
}

# Primary MySQL Server.
resource "azurerm_mysql_server" "primary" {
  name                = "primary-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login          = var.administrator_login
  administrator_login_password = random_password.login_password.result

  sku_name   = var.sku_name
  storage_mb = var.storage_mb
  version    = var.mysql_version

  auto_grow_enabled                 = false
  backup_retention_days             = var.backup_retention_days
  geo_redundant_backup_enabled      = var.geo_redundant_backup_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  public_network_access_enabled     = false
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"


  threat_detection_policy {
    enabled                     = true                 
    storage_endpoint            = azurerm_storage_account.sql_storage.primary_blob_endpoint
    storage_account_access_key  = azurerm_storage_account.sql_storage.primary_access_key
    retention_days              = 7
  }

  tags = var.tags
}

# Sets MySQL Configuration values on a MySQL Server.
resource "azurerm_mysql_configuration" "config" {
  for_each            = local.mysql_config

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.primary.name
  value               = each.value
}

