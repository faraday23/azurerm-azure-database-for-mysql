output "resource_group_name" {
  value = module.resource_group.name
}

output "private_dns_zone_name" {
  value = module.private_dns_zone.private_dns_zone_name
}

output "private_dns_zone_ids" {
  description = "dns zone id"
  value       = module.snet_endpoint.subnet_id
}

output "subnet_id" {
  description = "the name of the endpoint id."
  value       = module.snet_endpoint.subnet_id
}

output "virtual_network_name" {
  description = "the name of the endpoint id."
  value       = module.snet_endpoint.subnet_id
}

output "primary_blob_endpoint" {
  value = module.storage_acct.primary_blob_endpoint
}

output "primary_access_key" {
  value = module.storage_acct.primary_access_key
}

output "server_id" {
  value       = module.mysql_server.server_id
  description = "The ID of the mysql instance."
}

output "server_name" {
  value       = module.mysql_server.server_name
  description = "The Name of the mysql instance."
}


