##
# Required parameters
##

variable "resource_group_name" {
  description = "The name of the Resource Group in which the subnet endpoint exists."
  type        = string
}

variable "virtual_network_name" {
  description = "name of the virtual network"
  type        = string
}

variable "subnet_cidr" {
  description = "address of the subnet"
  type        = map(list(string))
}

variable "enforce_private_link_endpoint_network_policies" {
  description = "Enable or Disable network policies for the private link endpoint on the subnet. Default value is false. Conflicts with enforce_private_link_service_network_policies."
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
  description = "identifier appended to db name (productname-environment-mysql<db_id>)"
  type        = string
}
