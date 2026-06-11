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

output "efs_file_system_id" {
  value = data.terraform_remote_state.efs.outputs.file_system_id
}

output "efs_dns_name" {
  value = data.terraform_remote_state.efs.outputs.dns_name
}

output "elasticache_cluster_id" {
  value = data.terraform_remote_state.elasticache.outputs.cluster_id
}

output "elasticache_cache_nodes" {
  value = data.terraform_remote_state.elasticache.outputs.cache_nodes
}
