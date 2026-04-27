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

module "ec2" {
  source             = "../../../modules/ec2"
  env                = var.env
  project_name       = var.project_name
  ec2_instance_count = var.ec2_instance_count
  ec2_instance_type  = var.ec2_instance_type
  key_path           = var.key_path

  # Networkレイヤーから取得
  subnet_id               = data.terraform_remote_state.network.outputs.subnet_public_id_1a
  security_groups         = [module.security_group.public_sg_id]
  iam_instance_profile    = data.terraform_remote_state.iam.outputs.iam_instance_profile
  disable_api_termination = var.disable_api_termination
}

module "security_group" {
  source             = "../../../modules/sg"
  env                = var.env
  project_name       = var.project_name
  source_cidr_blocks = var.source_cidr_blocks
  target_cidr_blocks = var.target_cidr_blocks

  # Networkレイヤーから取得
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
}
