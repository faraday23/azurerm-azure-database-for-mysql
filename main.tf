# toggles on/off auditing and advanced threat protection policy for sql server
locals {
  if_threat_detection_policy_enabled = var.enable_threat_detection_policy ? [{}] : []

  create_password = (var.create_mode == "Default" ? (var.administrator_password == "" ? 1 : 0) : 0)

  administrator_login = (var.create_mode == "Default" ? var.administrator_login : null)

  administrator_password = (var.create_mode == "Default" ? (var.administrator_password == "" ? random_password.admin[0].result : var.administrator_password) : null)
}

# creates random password for admin account if not specified
resource "random_password" "admin" {
  count       = local.create_password
  length      = 24
  special     = true
}

resource "azurerm_mysql_server" "instance" {
  name                = "${var.names.product_name}-${var.names.environment}-mysql${var.server_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags = var.tags

  administrator_login          = local.administrator_login
  administrator_login_password = local.administrator_password

  sku_name   = var.sku_name
  storage_mb = var.storage_mb
  version    = var.mysql_version

  auto_grow_enabled                 = (var.create_mode == "Replica" ? true : var.auto_grow_enabled)
  backup_retention_days             = var.backup_retention_days
  geo_redundant_backup_enabled      = var.geo_redundant_backup_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  public_network_access_enabled     = (((length(var.service_endpoints) > 0) || (length(var.access_list) > 0)) ? true : false)
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"

  create_mode                       = var.create_mode
  creation_source_server_id         = (var.create_mode == "Replica" ? var.creation_source_server_id : null)

  dynamic "threat_detection_policy" {
      for_each = local.if_threat_detection_policy_enabled
      content {
          storage_endpoint           = var.storage_endpoint
          storage_account_access_key = var.storage_account_access_key 
          retention_days             = var.log_retention_days
      }
  }
}

# MySQL Database within a MySQL Server
resource "azurerm_mysql_database" "db" {
  for_each            = local.databases
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.instance.name
  charset             = each.value.charset
  collation           = each.value.collation
}

# Sets MySQL Configuration values on a MySQL Server.
resource "azurerm_mysql_configuration" "config" {
  for_each            = local.mysql_config
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.instance.name
  value               = each.value
}

data "azurerm_client_config" "current" {}

# Adding AD Admin to MySQL Server - Default is "false"
resource "azurerm_mysql_active_directory_administrator" "ad_admin" {
  count               = var.enable_mysql_ad_admin ? 1 : 0
  server_name         = azurerm_mysql_server.instance.name
  resource_group_name = var.resource_group_name
  login               = var.ad_admin_login_name 
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
}

# MySQL Service Endpoints 
resource "azurerm_mysql_virtual_network_rule" "service_endpoint" {
  for_each            = var.service_endpoints
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.instance.name
  subnet_id           = each.value
}

# MySQL Access List
resource "azurerm_mysql_firewall_rule" "access_list" {
  for_each            = var.access_list
  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.instance.name
  start_ip_address    = each.value.start_ip_address
  end_ip_address      = each.value.end_ip_address
}
