##
# Required parameters
##

variable "private_dns_zone_name" {
  description = "name of the dns zone"
  type        = string
}

variable "resource_group_name" {
  description = "name of the resoruce group"
  type        = string
}