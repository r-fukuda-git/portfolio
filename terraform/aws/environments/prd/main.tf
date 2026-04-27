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

module "iam" {
  source       = "../../modules/iam"
  env          = var.env
  project_name = var.project_name
}