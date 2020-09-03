##
# Required parameters
##

variable "subnet_id" {
  description = "The ID of the Subnet."
  type        = string
}

variable "location" {
  description = "location of resource."
  type        = string
}

variable "resource_group_name" {
  description = "location of resource."
  type        = string
} 
  
variable "names" {
  description = "names to be applied to resources"
  type        = map(string)
}

variable "tags" {
  description = "tags to be applied to resources"
  type        = map(string)
}

variable "db_id" {
  description = "Identifier appended to db name (productname-environment-mysql<db_id>)"
  type        = string
}

variable "private_service_connection" {
  description = "nested mode: NestingList, min items: 1, max items: 1"
  type = set(object(
    {
      is_manual_connection           = bool
      name                           = string
      private_connection_resource_id = string
      subresource_names              = list(string)
    }
  ))
}

variable "private_dns_zone_group" {
  description = "nested mode: NestingList, min items: 1, max items: 1"
  type = set(object(
    {
      name                           = string
      private_dns_zone_ids           = string
    }
  ))
}


