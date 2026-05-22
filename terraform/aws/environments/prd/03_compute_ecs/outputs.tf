output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

output "standalone_task_definition_arn" {
  value = module.ecs.standalone_task_definition_arn
}

output "standalone_schedule_enabled" {
  value = module.ecs.standalone_schedule_enabled
}

output "ecs_security_group_id" {
  value = module.security_group.private_ecs_sg_id
}

output "alb_security_group_id" {
  value = module.security_group.alb_sg_id
}
