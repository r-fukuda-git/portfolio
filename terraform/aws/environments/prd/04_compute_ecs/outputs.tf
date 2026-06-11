output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

output "ecs_security_group_id" {
  value = module.security_group.private_ecs_sg_id
}

output "alb_security_group_id" {
  value = module.security_group.alb_sg_id
}

output "efs_file_system_id" {
  value = module.efs.file_system_id
}

output "efs_dns_name" {
  value = module.efs.dns_name
}
