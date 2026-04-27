provider "aws" {
  region = "ap-northeast-1"
}

module "networking" {
  source             = "../../../modules/networking"
  env                = var.env
  project_name       = var.project_name
  cidr_block_vpc     = var.cidr_block_vpc
  route_cidr_block   = var.route_cidr_block
  source_cidr_blocks = var.source_cidr_blocks
  public_subnet_1a   = var.public_subnet_1a
  public_subnet_1c   = var.public_subnet_1c
  private_subnet_1a  = var.private_subnet_1a
  private_subnet_1c  = var.private_subnet_1c
}
