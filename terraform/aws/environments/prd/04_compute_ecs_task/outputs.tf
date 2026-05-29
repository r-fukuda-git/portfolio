output "standalone_task_definition_arn" {
  value = module.ecs_standalone.standalone_task_definition_arn
}

output "standalone_schedule_enabled" {
  value = module.ecs_standalone.standalone_schedule_enabled
}

output "ecs_cluster_name" {
  value = module.ecs_standalone.cluster_name
}
