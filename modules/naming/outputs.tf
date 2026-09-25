output "names" {
  description = "Map of standardized resource names"
  value       = local.names
}

output "region_short" {
  description = "Short region code"
  value       = local.region_short
}

output "prefix" {
  description = "project-environment prefix"
  value       = local.prefix
}
