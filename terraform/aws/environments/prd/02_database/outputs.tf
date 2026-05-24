output "public_security_group_id" {
  value = module.security_group.public_sg_id
}

output "private_security_group_id" {
  value = module.security_group.private_sg_id
}

output "db_secret_arn" {
  value = module.rds.db_secret_arn
}

output "db_instance_endpoint" {
  value = module.rds.db_instance_endpoint
}
