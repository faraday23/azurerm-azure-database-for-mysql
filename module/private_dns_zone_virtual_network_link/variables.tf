##
# Required parameters
##

variable "private_dns_zone_name" {
  description = "name of the dns zone"
  type        = string
}

variable "virtual_network_id" {
  description = "ID of the virtual network"
  type        = string
}

variable "resource_group_name" {
  description = "location of resources to be created."
  type        = string
}

variable "db_id" {
  description = "Identifier appended to db name (productname-environment-mysql<db_id>)"
  type        = string
}


