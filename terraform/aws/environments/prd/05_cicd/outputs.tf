output "github_oidc_provider_arn" {
  value = module.github_actions_oidc.oidc_provider_arn
}

output "github_actions_main_role_arn" {
  description = "Set as GitHub repository variable AWS_DEPLOY_ROLE_ARN for main-cd workflow"
  value       = module.github_actions_oidc.main_deploy_role_arn
}

output "github_actions_main_role_name" {
  value = module.github_actions_oidc.main_deploy_role_name
}

output "ecs_cluster_name" {
  # modules/ecs と同一命名。04_compute_ecs 未 apply でも plan 可能にする
  value = "${var.project_name}-${var.env}-ecs-cluster"
}

output "ecs_service_name" {
  value = "${var.project_name}-${var.env}-service"
}

output "ecr_repository_name" {
  value = data.terraform_remote_state.ecr.outputs.ecr_repository_name
}

output "ecr_repository_url" {
  value = data.terraform_remote_state.ecr.outputs.ecr_repository_url
}

output "ecs_container_name" {
  value = "${var.project_name}-${var.env}-service-container"
}
