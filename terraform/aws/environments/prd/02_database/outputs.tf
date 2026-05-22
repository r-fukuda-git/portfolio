output "public_security_group_id" {
  value = module.security_group.public_sg_id
}

output "private_security_group_id" {
  value = module.security_group.private_sg_id
}
