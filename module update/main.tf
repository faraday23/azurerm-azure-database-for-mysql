# A diagnostic setting specifies a list of categories of platform logs and/or metrics that you want to collect from a resource, 
# and one or more destinations that you would stream them to. Normal usage charges for the destination will occur. 
# Learn more about the different log categories and contents of those logs https://docs.microsoft.com/azure/azure-monitor/platform/diagnostic-settings?WT.mc_id=Portal-Microsoft_Azure_Monitoring

terraform {
  required_version = ">= 0.13.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.25.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.25.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "00000000-0000-0000-00000-00000000"
}

data "http" "my_ip" {
  url = "http://ipv4.icanhazip.com"
}

data "azurerm_subscription" "current" {
}

resource "random_string" "random" {
  length  = 12
  upper   = false
  special = false
}

# MySQL Additional config Server parameters
variable "table_open_cache_instances" {
  type        = string
  description = "The number of open tables cache instances. Allowed value should be: 1-16"
}

module "subscription" {
  source          = "github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = data.azurerm_subscription.current.subscription_id
}

module "rules" {
  source = "github.com/openrba/python-azure-naming.git?ref=working"
}

module "metadata" {
  source = "github.com/Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.1.0"

  naming_rules = module.rules.yaml

  market              = "us"
  project             = "https://gitlab.ins.risk.regn.net/example/"
  location            = "eastus2" # for location list see - https://github.com/openrba/python-azure-naming#rbaazureregion
  sre_team            = "iog-core-services"
  environment         = "sandbox" # for environment list see - https://github.com/openrba/python-azure-naming#rbaenvironment
  product_name        = random_string.random.result
  business_unit       = "iog"
  product_group       = "core"    # for product name list see - https://github.com/openrba/python-azure-naming#rbaproductname
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

module "virtual_network" {
  source = "github.com/Azure-Terraform/terraform-azurerm-virtual-network.git?ref=v2.3.1"

  naming_rules = module.rules.yaml

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  address_space = ["10.1.1.0/24"]

  subnets = {
    "iaas-outbound" = { cidrs = ["10.1.1.0/27"]
    service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"] }
  }
}

module "storage_account" {
  source = "github.com/openrba/terraform-azurerm-storage-account.git"

  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  names               = module.metadata.names
  tags                = module.metadata.tags

  account_kind     = "StorageV2"
  replication_type = "LRS"

  access_list = {
    "my_ip"      = chomp(data.http.my_ip.body)
  }

  service_endpoints = {
    "iaas-outbound" = module.virtual_network.subnet["iaas-outbound"].id
  }
}

module "mysql" {
  source = "github.com/openrba/terraform-azurerm-mysql-server.git"

  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  names               = module.metadata.names
  tags                = module.metadata.tags

  server_id = random_string.random.result

  service_endpoints = { "env1" = module.virtual_network.subnet["iaas-outbound"].id }
  access_list       = { "home" = { start_ip_address = chomp(data.http.my_ip.body), end_ip_address = chomp(data.http.my_ip.body) } }
  databases = { "foo" = {}
  "bar" = { charset = "utf16", collation = "utf16_general_ci" } }

  # Enable ad admin
  ad_admin_login_name = "mssql-group-signin-test-2@example.onmicrosoft.com"

  # advanced threat protection policy
  threat_detection_policy = {
    enable_threat_detection_policy   = true
    threat_detection_email_addresses = ["first.last@lexisnexisrisk.com", "first.last2@lexisnexisrisk.com"]
  }

  # Additional mysql server parameters
  mysql_server_parameters = {
    table_open_cache_instances = 2
  }
}

output "resource_group" {
  value = module.resource_group.name
}

output "mysql_fqdn" {
  value = module.mysql.fqdn
}

output "mysql_admin_login" {
  value = module.mysql.administrator_login
}

output "mysql_admin_password" {
  value = module.mysql.administrator_password
}

output "mysql_test_command" {
  value = "mysql -h ${module.mysql.fqdn} -u ${module.mysql.administrator_login}@${module.mysql.name} -p${module.mysql.administrator_password}"
}
