provider "aws" {
  region = "ap-northeast-1"
}

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

data "terraform_remote_state" "database" {
  count = var.use_database_security_groups ? 1 : 0

  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.database
  })
}

module "security_group" {
  count = var.use_database_security_groups ? 0 : 1

  source = "../../../modules/sg"

  env                = var.env
  project_name       = var.project_name
  source_cidr_blocks = var.source_cidr_blocks
  target_cidr_blocks = var.target_cidr_blocks
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id

  create_web_and_db_security_groups  = true
  create_ecs_and_alb_security_groups = false
}

locals {
  web_security_group_id = var.use_database_security_groups ? data.terraform_remote_state.database[0].outputs.public_security_group_id : module.security_group[0].public_sg_id
}

module "ec2" {
  source             = "../../../modules/ec2"
  env                = var.env
  project_name       = var.project_name
  ec2_instance_count = var.ec2_instance_count
  ec2_instance_type  = var.ec2_instance_type
  key_path           = var.key_path

  subnet_id               = data.terraform_remote_state.network.outputs.subnet_public_id_1a
  security_groups         = [local.web_security_group_id]
  iam_instance_profile    = data.terraform_remote_state.iam.outputs.iam_instance_profile
  disable_api_termination = var.disable_api_termination
}
