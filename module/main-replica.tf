# required server inputs
variable "srvr_id" {
  description = "identifier appended to srvr name for more info see https://github.com/[redacted]/python-azure-naming"
  type        = string
}

variable "srvr_id_replica" {
  description = "identifier appended to srvr name for more info see https://github.com/[redacted]/python-azure-naming"
  type        = string
}

# required tags
variable "names" {
  description = "names to be applied to resources"
  type        = map(string)
}

variable "tags" {
  description = "tags to be applied to resources"
  type        = map(string)
}

#diagnostic setting required variables
variable "sa_resource_group" {
    type        = string
    description = "Name of resource group the storage account resides in"
}

variable "storage_account" {
    type        = string
    description = "Name of storage account"
}

# Configure Azure Providers
provider "azurerm" {
  version = ">=2.25.0"
  subscription_id = "00000000-0000-0000-0000-00000000"
  features {}
}

##
# Pre-Build Modules 
##

module "subscription" {
  source          = "github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = "00000000-0000-0000-0000-00000000"
}

module "rules" {
  source = "git@github.com:[redacted]/python-azure-naming.git?ref=tf"
}

# For tags and info see https://github.com/Azure-Terraform/terraform-azurerm-metadata 
# For naming convention see https://github.com/[redacted]/python-azure-naming 
module "metadata" {
  source = "github.com/Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.1.0"

  naming_rules = module.rules.yaml
  
  market              = "us"
  location            = "uscent1" # for location list see - https://github.com/[redacted]/python-azure-naming#rbaazureregion
  sre_team            = "alpha"
  environment         = "sandbox" # for environment list see - https://github.com/[redacted]/python-azure-naming#rbaenvironment
  project             = "mysql"
  business_unit       = "iog"     
  product_group       = "tfe"
  product_name        = "mysql"   # for product name list see - https://github.com/[redacted]/python-azure-naming#rbaproductname
  subscription_id     = module.subscription.output.subscription_id
  subscription_type   = "nonprod"
  resource_group_type = "app"
}

# mysql-server storage account
module "storage_acct" {
  source = "../mysql-module-test/storage_account"
  # Required inputs 
  srvr_id               = "01"
  # Pre-Built Modules  
  location              = module.metadata.location
  names                 = module.metadata.names
  tags                  = module.metadata.tags
  resource_group_name   = "rg-azure-demo-mysql"
}

# mysql-server module
module "mysql_server" {
  source = "../mysql-module-test/mysql_replica"
  # Pre-Built Modules  
  location                  = module.metadata.location
  names                     = module.metadata.names
  tags                      = module.metadata.tags
  # Required inputs 
  srvr_id_replica           = "03" # must be unique value
  resource_group_name       = "rg-azure-demo-mysql"
  event_scheduler           = "ON"
  # Replica server required inputs
  enable_replica            = true
  create_mode               = "Replica"
  creation_source_server_id = "/subscriptions/00000000-0000-0000-0000-00000000/resourceGroups/rg-azure-demo-mysql/providers/Microsoft.DBforMySQL/servers/mysql-useast1-sandbox01/"
  replica_server_location   = "centralus"  #must be in different location than primary server, use this azure cli command to find available locations 'az account list-locations -o table'
  # MySQL server and database audit policies and advanced threat protection 
  enable_threat_detection_policy = false
  # Storage endpoints for atp logs
  storage_endpoint               = module.storage_acct.primary_blob_endpoint
  storage_account_access_key     = module.storage_acct.primary_access_key  
  # Storage account for disagnostics logs
  sa_resource_group = "rg-azure-demo-mysql"
  storage_account   = "sqlvalhqvn4pesccwq"
  # Enable azure ad admin
  enable_mysql_ad_admin          = false
  ad_admin_login_name            = "first.last@risk.regn.net"
  ad_admin_login_name_replica    = "first.last@risk.regn.net"
  # private link endpoint
  enable_private_endpoint        = false 
  public_network_access_enabled  = true      # public access will need to be enabled to use vnet rules
   # Vnet rule
  enable_vnet_rule               = false
  # Virtual network - for Existing virtual network
  vnet_resource_group_name         = "rg-azure-demo-mysql"             #must be existing resource group within same region as primary server
  vnet_replica_resource_group_name = "rg-azure-demo-mysql-centralus"   #must be existing resource group within same region as replica server
  virtual_network_name             = "vnet-sandbox-eastus-mysql-01"    #must be existing vnet with available address space
  virtual_network_name_replica     = "vnet-sandbox-centralus-mysql-03" #must be existing vnet with available address space
  subnet_name_primary              = "default" #must be existing subnet name 
  subnet_name_replica              = "default" #must be existing subnet name 
  # Firewall Rules to allow client IP
  enable_firewall_rules           = false
  firewall_rules = [
                {name             = "desktop-ip"
                start_ip_address  = "209.243.55.98"
                end_ip_address    = "209.243.55.98"}]
}


