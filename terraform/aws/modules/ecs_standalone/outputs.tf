output "standalone_task_definition_arn" {
  value = aws_ecs_task_definition.standalone.arn
}

output "standalone_schedule_enabled" {
  value = var.standalone_schedule_enabled
}

output "cluster_name" {
  value = var.cluster_name
}
