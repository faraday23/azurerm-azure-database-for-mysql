# Configure terraform and azure provider
terraform {
  required_version = ">= 0.12.28"

  required_providers {
    azurerm = ">= 2.24.0"
    random  = ">= 2.2.0"
  }
}