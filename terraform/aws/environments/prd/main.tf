provider "aws" {
  region = "ap-northeast-1"
}

module "security_group" {
  source             = "../../modules/sg"
  vpc_id             = module.networking.vpc_id
  env                = var.env
  project_name       = var.project_name
  source_cidr_blocks = var.source_cidr_blocks
  target_cidr_blocks = var.target_cidr_blocks
}

module "ec2" {
  source                  = "../../modules/ec2"
  env                     = var.env
  project_name            = var.project_name
  ec2_instance_count      = var.ec2_instance_count
  ec2_instance_type       = var.ec2_instance_type
  key_path                = var.key_path
  subnet_id               = module.networking.subnet_public_id_1a
  security_groups         = [module.security_group.public_sg_id]
  iam_instance_profile    = module.iam.iam_instance_profile
  disable_api_termination = var.disable_api_termination
}

module "iam" {
  source       = "../../modules/iam"
  env          = var.env
  project_name = var.project_name
}