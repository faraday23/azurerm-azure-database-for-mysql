# Configure Providers
provider "azurerm" {
  version = ">=2.0.0"
  subscription_id = "b0837458-adf3-41b0-a8fb-c16f9719627d"
  features {}
}

##
# Pre-Build Modules 
##

module "subscription" {
  source          = "github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = "b0837458-adf3-41b0-a8fb-c16f9719627d"
}

module "rules" {
  source = "git@github.com:openrba/python-azure-naming.git?ref=tf"
}

# For tags and info see https://github.com/Azure-Terraform/terraform-azurerm-metadata 
# For naming convention see https://github.com/openrba/python-azure-naming 
module "metadata" {
  source = "github.com/Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.0.0"

  naming_rules = module.rules.yaml
  
  market              = "us"
  location            = "useast1"
  sre_team            = "alpha"
  environment         = "sandbox"
  project             = "mysqlDB"
  business_unit       = "iog"
  product_group       = "tfe"
  product_name        = "mysqlsrvr"
  subscription_id     = module.subscription.output.subscription_id
  subscription_type   = "nonprod"
  resource_group_type = "app"
}

module "resource_group" {
  source = "github.com/Azure-Terraform/terraform-azurerm-resource-group.git?ref=v1.0.0"
  
  location = module.metadata.location
  names    = module.metadata.names
  tags     = module.metadata.tags
}

# mysql-server storage account
module "storage_acct" {
  source = "../mysql-module-test/storage_account"
  # Required inputs 
  db_id                 = "1337"
  
  # Pre-Built Modules  
  location              = module.metadata.location
  names                 = module.metadata.names
  tags                  = module.metadata.tags
  resource_group_name   = module.resource_group.name
}

# deploy new vnet for private link endpoint+
module "virtual_network" {
  source = "github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v1.0.0"

  naming_rules = module.rules.yaml

  # Pre-Built Modules
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  address_space = ["192.168.123.0/24"]

  subnets = {
    "01-iaas-private"     = ["192.168.123.0/27"]
    "02-iaas-public"      = ["192.168.123.32/27"]
    "03-iaas-outbound"    = ["192.168.123.64/27"]
  }
}

# Manages a subnet. Subnets represent network segments within the IP space defined by the virtual network.
module "snet_endpoint" {
  source = "../mysql-module-test/snet_endpoint"
  # Required inputs 
  virtual_network_name = module.virtual_network.vnet
  subnet_cidr          = module.virtual_network.subnet["iaas-private-subnet"].address_prefixes
  enforce_private_link_endpoint_network_policies = true
  db_id                = "1337"

  # Pre-Built Modules  
  names               = module.metadata.names
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name
}

# mysql-server module
module "mysql_server" {
  source = "../mysql-module-test/mysql_server"
  # Required inputs 
  db_id                       = "1337"
  create_mode                 = "Default"

  threat_detection_policy = [{
    enabled                     = true   
    storage_endpoint            = module.storage_acct.primary_blob_endpoint
    storage_account_access_key  = module.storage_acct.primary_access_key         
    retention_days              = 7
  }]

  # Pre-Built Modules  
  location            = module.metadata.location
  names               = module.metadata.names
  tags                = module.metadata.tags
  resource_group_name = module.resource_group.name
}

module "private_dns_zone" {
  source = "../mysql-module-test/private_dns_zone"
  # Required inputs 
  private_dns_zone_name = "privatelink.mysql.database.azure.com"

  # Pre-Built Modules  
  resource_group_name   = module.resource_group.name
}

module "private_dns_zone_virtual_network_link" {
  source = "../mysql-module-test/private_dns_zone_virtual_network_link"
  # Required inputs 
  private_dns_zone_name = module.private_dns_zone.private_dns_zone_name
  virtual_network_id    = module.virtual_network.vnet.id
  db_id                 = "1337"

  # Pre-Built Modules  
  resource_group_name   = module.resource_group.name
}

module "private_link_endpoint" {
  source = "../mysql-module-test/private_link_endpoint"
  # Required inputs 
  subnet_id             = module.snet_endpoint.id
  db_id                 = "1337"
   # Pre-Built Modules  
  location              = module.metadata.location
  names                 = module.metadata.names
  tags                  = module.metadata.tags
  resource_group_name   = module.resource_group.name

  private_service_connection = [{
    name                           = "prv-serv-conn-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
    private_connection_resource_id = module.mysql_server.id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }]

  private_dns_zone_group = [{
    name                 = module.private_dns_zone.private_dns_zone_name
    private_dns_zone_ids = module.private_dns_zone.id
  }]
}





