# Manages a subnet. Subnets represent network segments within the IP space defined by the virtual network.
resource "azurerm_subnet" "snet_endpoint" {
  name                 = "snet-endpoint-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.subnet_cidr

  enforce_private_link_endpoint_network_policies = var.enforce_private_link_endpoint_network_policies
}


