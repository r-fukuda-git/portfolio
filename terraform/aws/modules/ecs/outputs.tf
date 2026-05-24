output "cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  value = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "service_name" {
  value = aws_ecs_service.this.name
}

output "service_task_definition_arn" {
  value = aws_ecs_task_definition.service.arn
}

output "standalone_task_definition_arn" {
  value = aws_ecs_task_definition.standalone.arn
}

output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.service.arn
}

output "standalone_schedule_enabled" {
  value = var.standalone_schedule_enabled
}
