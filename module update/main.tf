# toggles on/off auditing and advanced threat protection policy for sql server
locals {
    if_threat_detection_policy_enabled  = var.enable_threat_detection_policy ? [{}] : []                
}

# creates random password for mysql admin account
resource "random_password" "login_password" {
  length      = 24
  special     = true
}

# MySQL Server Primary server
resource "azurerm_mysql_server" "primary" {
  name                = "primary-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  location            = var.location
  resource_group_name = var.resource_group_name

  administrator_login          = var.administrator_login
  administrator_login_password = random_password.login_password.result

  sku_name   = var.sku_name
  storage_mb = var.storage_mb
  version    = var.mysql_version

  auto_grow_enabled                 = var.auto_grow_enabled
  backup_retention_days             = var.backup_retention_days
  geo_redundant_backup_enabled      = var.geo_redundant_backup_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"

  dynamic "threat_detection_policy" {
      for_each = local.if_threat_detection_policy_enabled
      content {
          state                      = "Enabled"
          storage_endpoint           = var.storage_endpoint
          storage_account_access_key = var.storage_account_access_key 
          retention_days             = var.log_retention_days
      }
  }

  tags = var.tags
}

# MySQL Server Replica server - Default is false
resource "azurerm_mysql_server" "replica" {
  count               = var.enable_replica ? 1 : 0
  name                = "replica-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  location            = var.location_replica
  resource_group_name = var.resource_group_name

  administrator_login          = var.administrator_login
  administrator_login_password = random_password.login_password.result

  sku_name   = var.sku_name
  storage_mb = var.storage_mb
  version    = var.mysql_version

  auto_grow_enabled                 = var.auto_grow_enabled
  backup_retention_days             = var.backup_retention_days
  geo_redundant_backup_enabled      = var.geo_redundant_backup_enabled
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  public_network_access_enabled     = var.public_network_access_enabled
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
  create_mode                       = var.create_mode
  creation_source_server_id         = azurerm_mysql_server.primary.id

  dynamic "threat_detection_policy" {
      for_each = local.if_threat_detection_policy_enabled
      content {
          state                      = "Enabled"
          storage_endpoint           = var.storage_endpoint
          storage_account_access_key = var.storage_account_access_key 
          retention_days             = var.log_retention_days
      }
  }

  tags = var.tags
}

# MySQL Database within a MySQL Server
resource "azurerm_mysql_database" "db" {
  count               = var.enable_db ? 1 : 0
  name                = "sql-mysqldb-${var.names.product_name}-${var.names.environment}-mssql${var.db_id}"
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.primary.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
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

# Adding AD Admin to MySQL Server - Secondary server depend on Failover Group - Default is "false"
data "azurerm_client_config" "current" {}

resource "azurerm_mysql_active_directory_administrator" "aduser1" {
  count               = var.enable_mysql_ad_admin ? 1 : 0
  server_name         = azurerm_mysql_server.primary.name
  resource_group_name = var.resource_group_name
  login               = var.ad_admin_login_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
}

resource "azurerm_mysql_active_directory_administrator" "aduser2" {
  count               = var.enable_replica && var.enable_mysql_ad_admin ? 1 : 0
  server_name         = azurerm_mysql_server.replica.0.name
  resource_group_name = var.resource_group_name
  login               = var.ad_admin_login_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  object_id           = data.azurerm_client_config.current.object_id
}

# Azure MySQL Firewall Rule - Default is "false"
resource "azurerm_mysql_firewall_rule" "fw01" {
  count               = var.enable_firewall_rules && length(var.firewall_rules) > 0 ? length(var.firewall_rules) : 0
  name                = element(var.firewall_rules, count.index).name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.primary.name
  start_ip_address    = element(var.firewall_rules, count.index).start_ip_address
  end_ip_address      = element(var.firewall_rules, count.index).end_ip_address
}

resource "azurerm_mysql_firewall_rule" "fw02" {
  count               = var.enable_replica && var.enable_firewall_rules && length(var.firewall_rules) > 0 ? length(var.firewall_rules) : 0
  name                = element(var.firewall_rules, count.index).name
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.replica.0.name
  start_ip_address    = element(var.firewall_rules, count.index).start_ip_address
  end_ip_address      = element(var.firewall_rules, count.index).end_ip_address
}

# MySQL Virtual Network Rule - Default is "false"
resource "azurerm_mysql_virtual_network_rule" "vn_rule01" {
  count = var.enable_vnet_rule && length(var.allowed_subnets) > 0 ? length(var.allowed_subnets) : 0

  name = format(
    "%s-%s",
    element(split("/", var.allowed_subnets[count.index]), 8), # VNet name
    element(split("/", var.allowed_subnets[count.index]), 10) # Subnet name
  )
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.primary.name
  subnet_id           = var.allowed_subnets[count.index]
}

# MySQL Virtual Network Rule for Replica - Default is "false"
resource "azurerm_mysql_virtual_network_rule" "vn_rule02" {
 count = var.enable_replica && var.enable_vnet_rule && length(var.allowed_subnets) > 0 ? length(var.allowed_subnets) : 0

  name = format(
    "%s-%s",
    element(split("/", var.allowed_subnets[count.index]), 8), # VNet name
    element(split("/", var.allowed_subnets[count.index]), 10) # Subnet name
  )
  resource_group_name = var.resource_group_name
  server_name         = azurerm_mysql_server.replica.name
  subnet_id           = var.allowed_subnets[count.index]
}

# Private Link Endpoint for MySQL Server - Existing vnet
data "azurerm_virtual_network" "vnet01" {
  name                = var.virtual_network_name
  resource_group_name = var.resource_group_name
}

# Private Link Endpoint for MySQL Server - Default is "false" 
resource "azurerm_subnet" "snet_ep" {
    count                   = var.enable_private_endpoint ? 1 : 0
    name                    = var.subnet_name
    resource_group_name     = var.resource_group_name
    virtual_network_name    = var.virtual_network_name
    address_prefixes        = var.private_subnet_address_prefix
    enforce_private_link_endpoint_network_policies = true
}

# Azure Private Endpoint is a network interface that connects you privately and securely to a service powered by Azure Private Link. 
# Private Endpoint uses a private IP address from your VNet, effectively bringing the service into your VNet. The service could be an Azure service such as Azure Storage, MySQL, etc. or your own Private Link Service.
resource "azurerm_private_endpoint" "pep1" {
  count               = var.enable_private_endpoint ? 1 : 0    
  name                = "mysql-endpoint-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.snet_ep.id

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

# Azure Private Endpoint is a network interface that connects you privately and securely to a service powered by Azure Private Link. 
# Private Endpoint uses a private IP address from your VNet, effectively bringing the service into your VNet. The service could be an Azure service such as Azure Storage, SQL, etc. or your own Private Link Service.
resource "azurerm_private_endpoint" "pep2" {
  count               = var.enable_replica && var.enable_private_endpoint ? 1 : 0  
  name                = "mysql-endpoint-replica${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.snet_ep.id

  private_service_connection {
    name                           = "prv-serv-conn-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
    private_connection_resource_id = azurerm_mysql_server.replica.id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = azurerm_mysql_server.replica.name
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone.id]
  }
   tags = var.tags
}

# DNS zone & records for MySQL Private endpoints - Default is "false" 
data "azurerm_private_endpoint_connection" "private_ip1" {
    count               = var.enable_private_endpoint ? 1 : 0    
    name                = azurerm_private_endpoint.pep1.0.name
    resource_group_name = var.resource_group_name
    depends_on          = [azurerm_mysql_server.primary]
}

data "azurerm_private_endpoint_connection" "private_ip2" {
    count               = var.enable_replica && var.enable_private_endpoint ? 1 : 0
    name                = azurerm_private_endpoint.pep2.0.name
    resource_group_name = var.resource_group_name
    depends_on          = [azurerm_mysql_server.secondary]
}

# Enables you to manage Private DNS zone Virtual Network Links. 
# These Links enable DNS resolution and registration inside Azure Virtual Networks using Azure Private DNS.
resource "azurerm_private_dns_zone" "dns_zone" {
  count               = var.enable_private_endpoint ? 1 : 0    
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}

# Enables you to manage Private DNS zone Virtual Network Links. 
# These Links enable DNS resolution and registration inside Azure Virtual Networks using Azure Private DNS.
resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_vnet" {
  count                 = var.enable_private_endpoint ? 1 : 0    
  name                  = "dns-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}


# Enables you to manage DNS A Records within Azure Private DNS.
resource "azurerm_private_dns_a_record" "arecord1" {
    count               = var.enable_private_endpoint ? 1 : 0
    name                = azurerm_mysql_server.primary.name
    zone_name           = azurerm_private_dns_zone.dnszone1.0.name
    resource_group_name = var.resource_group_name
    ttl                 = 300
    records             = [data.azurerm_private_endpoint_connection.private_ip1.0.private_service_connection.0.private_ip_address]
}

# Enables you to manage DNS A Records within Azure Private DNS.
resource "azurerm_private_dns_a_record" "arecord2" {
    count               = var.enable_replica && var.enable_private_endpoint ? 1 : 0
    name                = azurerm_mysql_server.replica.0.name
    zone_name           = azurerm_private_dns_zone.dnszone1.0.name
    resource_group_name = var.resource_group_name
    ttl                 = 300
    records             = [data.azurerm_private_endpoint_connection.private_ip2.0.private_service_connection.0.private_ip_address]
}

# The mysql_user resource creates and manages a user on a MySQL server.
resource "mysql_user" "users" {
  count = var.create_databases_users && length(var.databases_names) ? 1 : 0

  provider = mysql.create-users

  user               = (var.enable_user_suffix ? format("%s_user", var.databases_names[count.index]) : var.databases_names[count.index])
  plaintext_password = random_password.login_password[count.index].result
  host               = "%"

  depends_on = [azurerm_mysql_database.mysql_db, azurerm_mysql_firewall_rule.firewall_rules]
}

# The mysql_user resource creates and manages a user on a MySQL server.
resource "mysql_grant" "roles" {
  count = var.create_databases_users && length(var.databases_names) ? 1 : 0

  provider = mysql.create_users

  user       = (var.enable_user_suffix ? format("%s_user", var.databases_names[count.index]) : var.databases_names[count.index])
  host       = "%"
  database   = var.databases_names[count.index]
  privileges = ["ALL"]

  depends_on = [mysql_user.users]
}
