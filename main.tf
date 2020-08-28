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

# Meets security policy requirement by adding AzureNetwork DDoS Protection Plan.
resource "azurerm_network_ddos_protection_plan" "ddos" {
  name                = "ddos-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Manages a virtual network including any configured subnets. Each subnet can optionally be configured with a security group to be associated with the subnet.
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name

  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.ddos.id
    enable = true
  }
}

# Manages a subnet. Subnets represent network segments within the IP space defined by the virtual network.
resource "azurerm_subnet" "snet" {
  name                 = "snet-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  enforce_private_link_service_network_policies = true
}

# Manages a subnet. Subnets represent network segments within the IP space defined by the virtual network.
resource "azurerm_subnet" "snet_endpoint" {
  name                 = "snet-endpoint-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  enforce_private_link_endpoint_network_policies = true
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
  create_mode                       = "Default"

  threat_detection_policy {
    enabled                     = true                 
    storage_endpoint            = azurerm_storage_account.sql_storage.primary_blob_endpoint
    storage_account_access_key  = azurerm_storage_account.sql_storage.primary_access_key
    retention_days              = 7
  }

  tags = var.tags
}

# Replica MySQL Server. 
resource "azurerm_mysql_server" "replica" {
  name                = "replica-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  location            = var.location_replica
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
  create_mode                       = "Replica"
  creation_source_server_id         = azurerm_mysql_server.primary.id

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

# Sets MySQL Configuration values on a MySQL Server.
resource "azurerm_mysql_configuration" "config_replica" {
  for_each            = local.mysql_config

  name                = each.key
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.replica.name
  value               = each.value
}

# Enables you to manage Private DNS zone Virtual Network Links. 
# These Links enable DNS resolution and registration inside Azure Virtual Networks using Azure Private DNS.
resource "azurerm_private_dns_zone" "dns_zone" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}

# Enables you to manage Private DNS zone Virtual Network Links. 
# These Links enable DNS resolution and registration inside Azure Virtual Networks using Azure Private DNS.
resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_vnet" {
  name                  = "dns-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# Azure Private Endpoint is a network interface that connects you privately and securely to a service powered by Azure Private Link. 
# Private Endpoint uses a private IP address from your VNet, effectively bringing the service into your VNet. The service could be an Azure service such as Azure Storage, SQL, etc. or your own Private Link Service.
resource "azurerm_private_endpoint" "mysql_endpoint" {
  name                = "mysql-endpoint-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.snet_endpoint.id

  private_service_connection {
    name                           = "prv-serv-conn-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
    private_connection_resource_id = azurerm_mysql_server.primary.id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_mysql_server.primary.name
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone.id]
  }

   tags = var.tags
}



