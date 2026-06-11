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

module "security_group" {
  source = "../../../modules/sg"

  env                = var.env
  project_name       = var.project_name
  source_cidr_blocks = var.source_cidr_blocks
  target_cidr_blocks = var.target_cidr_blocks
  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id

  create_web_security_group            = true
  create_web_and_db_security_groups    = false
  create_ecs_and_alb_security_groups   = false
}

module "ec2" {
  source             = "../../../modules/ec2"
  env                = var.env
  project_name       = var.project_name
  ec2_instance_count = var.ec2_instance_count
  ec2_instance_type  = var.ec2_instance_type
  key_path           = var.key_path

  subnet_id               = data.terraform_remote_state.network.outputs.subnet_public_id_1a
  security_groups         = [module.security_group.public_sg_id]
  iam_instance_profile    = data.terraform_remote_state.iam.outputs.iam_instance_profile
  disable_api_termination = var.disable_api_termination
}

module "efs" {
  source = "../../../modules/efs_stack"

  project_name = var.project_name
  env          = var.env
  vpc_id       = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_public_id_1a,
    data.terraform_remote_state.network.outputs.subnet_public_id_1c
  ]
  client_security_group_ids = [module.security_group.public_sg_id]

  expected_storage_gb = var.efs_expected_storage_gb
  performance_mode    = var.efs_performance_mode
  throughput_mode     = var.efs_throughput_mode
}
