data "terraform_remote_state" "iam" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.iam
  })
}

data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.ecs
  })
}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.ecr
  })
}

module "github_actions_oidc" {
  source = "../../../modules/github_actions_oidc"

  env               = var.env
  project_name      = var.project_name
  github_owner      = var.github_owner
  github_repository = var.github_repository

  main_deploy_branches = [var.main_branch]

  ecr_repository_arn          = data.terraform_remote_state.ecr.outputs.ecr_repository_arn
  ecs_task_execution_role_arn = data.terraform_remote_state.iam.outputs.ecs_task_execution_role_arn
  ecs_task_role_arn           = data.terraform_remote_state.iam.outputs.ecs_task_role_arn
}
