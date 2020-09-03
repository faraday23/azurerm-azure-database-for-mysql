##
# Required parameters
# These parameters must be supplied when consuming this module.
##

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "name of the resource group to hold the resource"
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
