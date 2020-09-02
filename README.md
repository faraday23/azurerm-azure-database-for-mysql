# Azure Database for MySQL Server

This repo contains an example Terraform configuration that deploys a MySQL database using Azure.
For more info, please see https://docs.microsoft.com/en-us/azure/mysql/.

## Example Usage

```hcl
# Configure Providers
provider "azurerm" {
  version = ">=2.0.0"
  subscription_id = "0000000-0000-0000-0000-0000000"
  features {}
}

##
# Pre-Build Modules 
##

module "subscription" {
  source = "github.com/Azure-Terraform/terraform-azurerm-subscription-data.git?ref=v1.0.0"
  subscription_id = "0000000-0000-0000-0000-0000000"
}

module "rules" {
  source = "git@github.com:openrba/python-azure-naming.git?ref=tf"
}

# For tags and info see https://github.com/Azure-Terraform/terraform-azurerm-metadata 
# and for naming convention https://github.com/openrba/python-azure-naming 
module "metadata"{
  source = "github.com/Azure-Terraform/terraform-azurerm-metadata.git?ref=v1.1.0"

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

# mysql-server module
module "mysql_server" {
  source = "github.com/Azure-Terraform/terraform-azurerm-mysql-server.git?ref=condense"
  # Required inputs 
  db_id                 = "1337"
  # Pre-Built Modules  
  location              = module.metadata.location
  names                 = module.metadata.names
  tags                  = module.metadata.tags
  resource_group_name   = module.resource_group.name
}
```
## Required Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| subscription_name | Name of Azure Subscription | `string` | n/a | yes |
| app_name | Server Name for Azure database for MySQL | `string` | n/a | yes |
| sku_size_mb | Azure database for MySQL Sku Size| `string` | `"10240"` | yes |
| sku_tier | Azure database for MySQL pricing tier | `string` | `"GeneralPurpose"` | yes |
| sku_family | Azure database for MySQL sku family | `string` | `"Gen5"` | yes |
| my_sql_version | MySQL version 5.7 or 8.0 | `string` | `"8.0"` | yes |
| location | Location for all resources | `string` | n/a | yes |
| ARM_TENANT_ID | Azure Tenant ID | `string` | `"00000000-0000-0000-0000-000000000000"` | yes |
| ARM_SUBSCRIPTION_ID | Subscription ID where you would like to deploy the resources | `string` | `"00000000-0000-0000-0000-000000000000"` | yes |
  

## Quick start

1.Install [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).\
2.Sign into your [Azure Account](https://docs.microsoft.com/en-us/cli/azure/authenticate-azure-cli?view=azure-cli-latest)


```
# Login with the Azure CLI/bash terminal/powershell by running
az login

# Verify you are connected to correct subscription
az account set --subscription 00000000-0000-0000-0000-000000000000

# Confirm you are running required/pinned version of terraform
terraform version
```

Deploy the code:

```
terraform init
terraform plan -out azure-mysql-01.tfplan
terraform apply azure-mysql-01.tfplan
```



