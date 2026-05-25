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

module "security_group" {
  source = "../../../modules/sg"

  env                = var.env
  project_name       = var.project_name
  source_cidr_blocks = var.source_cidr_blocks
  target_cidr_blocks = var.target_cidr_blocks
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  container_port     = var.service_container_port

  create_web_and_db_security_groups  = false
  create_ecs_and_alb_security_groups = true
}

module "ecs" {
  source       = "../../../modules/ecs"
  env          = var.env
  project_name = var.project_name

  ecr_repository_url     = data.terraform_remote_state.ecr.outputs.ecr_repository_url
  service_image_tag      = var.service_image_tag
  service_container_port = var.service_container_port
  service_host_port      = var.service_container_port
  service_desired_count  = var.service_desired_count

  execution_role_arn = data.terraform_remote_state.iam.outputs.ecs_task_execution_role_arn
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id

  subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_private_id_1a,
    data.terraform_remote_state.network.outputs.subnet_private_id_1c
  ]
  public_subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_public_id_1a,
    data.terraform_remote_state.network.outputs.subnet_public_id_1c
  ]

  security_group_ids     = [module.security_group.private_ecs_sg_id]
  alb_security_group_ids = [module.security_group.alb_sg_id]

  standalone_image               = var.standalone_image
  standalone_command             = var.standalone_command
  standalone_schedule_enabled    = var.standalone_schedule_enabled
  standalone_schedule_expression = var.standalone_schedule_expression
}
