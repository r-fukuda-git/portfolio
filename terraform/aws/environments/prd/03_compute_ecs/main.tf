provider "aws" {
  region = "ap-northeast-1"
}

data "terraform_remote_state" "network" {
  backend = "local"
  config = {
    path = "../01_network/terraform.tfstate"
  }
}

data "terraform_remote_state" "iam" {
  backend = "local"
  config = {
    path = "../00_iam/terraform.tfstate"
  }
}

module "security_group" {
  source = "../../../modules/sg"

  env                = var.env
  project_name       = var.project_name
  source_cidr_blocks = var.source_cidr_blocks
  target_cidr_blocks = var.target_cidr_blocks
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  ecs_container_port = var.container_port

  create_web_and_db_security_groups  = false
  create_ecs_and_alb_security_groups = true
}

module "ecs" {
  source       = "../../../modules/ecs"
  env          = var.env
  project_name = var.project_name

  image         = var.image
  containerPort = var.container_port
  hostPort      = var.container_port
  desired_count = var.desired_count

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
  enable_standalone_schedule     = var.enable_standalone_schedule
  standalone_schedule_expression = var.standalone_schedule_expression
}
