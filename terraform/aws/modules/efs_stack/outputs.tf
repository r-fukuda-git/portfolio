output "file_system_id" {
  value = local.efs_exists ? data.aws_efs_file_system.existing[0].id : module.efs[0].file_system_id
}

output "file_system_arn" {
  value = local.efs_exists ? data.aws_efs_file_system.existing[0].arn : module.efs[0].file_system_arn
}

output "dns_name" {
  value = local.efs_exists ? data.aws_efs_file_system.existing[0].dns_name : module.efs[0].dns_name
}

output "security_group_id" {
  value = local.efs_security_group_id
}

output "managed_in_this_stack" {
  value = !local.efs_exists
}
