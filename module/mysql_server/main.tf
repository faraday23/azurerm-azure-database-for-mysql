# creates random password for mysql admin account
resource "random_password" "login_password" {
  length      = 24
  special     = true
}

# Manages a MySQL Server.
resource "azurerm_mysql_server" "server" {
  name                = "${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
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

  dynamic "threat_detection_policy" {
    for_each = var.threat_detection_policy
    content {
      enabled                    = threat_detection_policy.value["enabled"]
      storage_endpoint           = threat_detection_policy.value["primary_blob_endpoint"]
      storage_account_access_key = threat_detection_policy.value["primary_access_key"]
      retention_days             = threat_detection_policy.value["retention_days"]
    }
  }

  tags = var.tags
}

# Sets MySQL Configuration values on a MySQL Server.
resource "azurerm_mysql_configuration" "config" {
  for_each = local.mysql_config

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.server.name
  value               = each.value
}