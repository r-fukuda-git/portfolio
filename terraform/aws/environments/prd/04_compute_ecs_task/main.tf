data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

data "terraform_remote_state" "iam" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.iam
  })
}

data "terraform_remote_state" "ecr" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.ecr
  })
}

data "terraform_remote_state" "ecs" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.ecs
  })
}

data "aws_ecr_repository" "app" {
  name = "${var.project_name}-${var.env}-${var.ecr_repository_suffix}"
}

locals {
  ecs_cluster_name = try(
    data.terraform_remote_state.ecs.outputs.ecs_cluster_name,
    "${var.project_name}-${var.env}-ecs-cluster"
  )
  ecr_repository_url = try(
    data.terraform_remote_state.ecr.outputs.ecr_repository_url,
    data.aws_ecr_repository.app.repository_url
  )
  ecs_security_group_id = try(
    data.terraform_remote_state.ecs.outputs.ecs_security_group_id,
    data.aws_security_group.ecs.id
  )
}

data "aws_ecs_cluster" "service" {
  cluster_name = local.ecs_cluster_name
}

data "aws_security_group" "ecs" {
  name   = "${var.project_name}-${var.env}-ecs-sg"
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}

module "ecs_standalone" {
  source       = "../../../modules/ecs_standalone"
  env          = var.env
  project_name = var.project_name

  cluster_arn  = data.aws_ecs_cluster.service.arn
  cluster_name = local.ecs_cluster_name

  execution_role_arn = data.terraform_remote_state.iam.outputs.ecs_task_execution_role_arn
  task_role_arn      = data.terraform_remote_state.iam.outputs.ecs_task_role_arn

  ecr_repository_url = local.ecr_repository_url
  service_image_tag  = var.service_image_tag

  subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_private_id_1a,
    data.terraform_remote_state.network.outputs.subnet_private_id_1c
  ]
  security_group_ids = [local.ecs_security_group_id]

  standalone_image               = var.standalone_image
  standalone_command             = var.standalone_command
  standalone_schedule_enabled    = var.standalone_schedule_enabled
  standalone_schedule_expression = var.standalone_schedule_expression
}
