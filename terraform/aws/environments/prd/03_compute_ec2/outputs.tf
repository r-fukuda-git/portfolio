output "ec2_instance_ids" {
  value = module.ec2.ec2_instance_id
}

output "ec2_public_ips" {
  value = module.ec2.ec2_public_ip
}

output "ec2_private_ips" {
  value = module.ec2.ec2_private_ip
}

output "web_security_group_id" {
  value = local.web_security_group_id
}
