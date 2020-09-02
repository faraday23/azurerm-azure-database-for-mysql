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
  source = "github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = "b0837458-adf3-41b0-a8fb-c16f9719627d"
}

module "rules" {
  source = "git@github.com:openrba/python-azure-naming.git?ref=tf"
}

# For tags and info see https://github.com/Azure-Terraform/terraform-azurerm-metadata 
# For naming convention see https://github.com/openrba/python-azure-naming 
module "metadata"{
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

# mysql-server module
module "mysql_server" {
  source = "../mysql-module-test/mysql_server"
  # Required inputs 
  db_id                       = "1337"
  create_mode                 = "Default"
  storage_endpoint            = module.storage_acct.output.primary_blob_endpoint
  storage_account_access_key  = module.storage_acct.output.primary_access_key

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
  location              = module.metadata.location
  names                 = module.metadata.names
  tags                  = module.metadata.tags
  resource_group_name   = module.resource_group.name
}

module "private_dns_zone_virtual_network_link" {
  source = "../mysql-module-test/private_dns_zone_virtual_network_link"
  # Required inputs 
  private_dns_zone_name = module.private_dns_zone.output.private_dns_zone_name
  virtual_network_id    = module.virtual_network.output.id

  # Pre-Built Modules  
  location              = module.metadata.location
  names                 = module.metadata.names
  tags                  = module.metadata.tags
  resource_group_name   = module.resource_group.name
}

module "private_link_endpoint" {
  source = "../mysql-module-test/private_link_endpoint"
  # Required inputs 
  db_id                          = "1337"
  private_connection_resource_id = module.mysql_server.id
  private_dns_zone_group         = module.mysql_server.name
  virtual_network_name           = "vnet-sandbox-eastus-mysql-01"
  virtual_network_id             = "/subscriptions/b0837458-adf3-41b0-a8fb-c16f9719627d/resourceGroups/rg-azure-demo-mysql/providers/Microsoft.Network/virtualNetworks/vnet-sandbox-eastus-mysql-01"
  subnet_id                      = "/subscriptions/b0837458-adf3-41b0-a8fb-c16f9719627d/resourceGroups/rg-azure-demo-mysql/providers/Microsoft.Network/virtualNetworks/vnet-sandbox-eastus-mysql-01/subnets/default"
  
  # Pre-Built Modules  
  location              = module.metadata.location
  names                 = module.metadata.names
  tags                  = module.metadata.tags
  resource_group_name   = module.resource_group.name
}





