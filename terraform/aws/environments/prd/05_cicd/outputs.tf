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
  value = data.terraform_remote_state.ecs.outputs.ecs_cluster_name
}

output "ecs_service_name" {
  value = data.terraform_remote_state.ecs.outputs.ecs_service_name
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
