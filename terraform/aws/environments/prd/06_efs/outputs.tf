output "efs_file_system_id" {
  value = module.efs.file_system_id
}

output "efs_file_system_arn" {
  value = module.efs.file_system_arn
}

output "efs_dns_name" {
  value = module.efs.dns_name
}

output "efs_security_group_id" {
  value = module.efs.security_group_id
}

output "efs_client_security_group_ids" {
  value = local.client_security_group_ids
}
