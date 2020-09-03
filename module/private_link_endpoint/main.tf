# Azure Private Endpoint is a network interface that connects you privately and securely to a service powered by Azure Private Link. 
# Private Endpoint uses a private IP address from your VNet, effectively bringing the service into your VNet. 
# The service could be an Azure service such as Azure Storage, SQL, etc. or your own Private Link Service.
# Note: Private Endpoint Cannot Be Created InSubnet That Has Network Policies Enabled 
resource "azurerm_private_endpoint" "mysql_endpoint" {
  name                = "mysql-endpoint-${var.names.product_name}-${var.names.environment}-mysql${var.db_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  dynamic "private_service_connection" {
    for_each = var.private_service_connection
    content {
      is_manual_connection           = private_service_connection.value["is_manual_connection"]
      name                           = private_service_connection.value["name"]
      private_connection_resource_id = private_service_connection.value["private_connection_resource_id"]
      subresource_names              = private_service_connection.value["subresource_names"]
    }
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_group
    content {
      name                 = private_service_connection.value["name"]
      private_dns_zone_ids = private_service_connection.value["private_dns_zone_ids"]
    }
  }

   tags = var.tags
}