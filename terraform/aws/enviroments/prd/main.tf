provider "aws" {
    region = "ap-northeast-1"
}

module "networking" {
    source = "../../modules/networking"
    env = var.env
    project_name = var.project_name
    cidr_block_vpc = var.cidr_block_vpc
    route_cidr_block = var.route_cidr_block
    source_cidr_blocks = var.source_cidr_blocks
    public_subnet_1a = var.public_subnet_1a
    public_subnet_1c = var.public_subnet_1c
    private_subnet_1a = var.private_subnet_1a
    private_subnet_1c = var.private_subnet_1c
}

module "security_group" {
    source = "../../modules/sg"
    vpc_id = module.networking.vpc_id
    env = var.env
    project_name = var.project_name
    source_cidr_blocks = var.source_cidr_blocks
}

module "ec2" {
    source = "../../modules/ec2"
    env = var.env
    project_name = var.project_name
    ec2_instance_count = var.ec2_instance_count
    ec2_instance_type = var.ec2_instance_type
    key_path = var.key_path
    subnet_id = module.networking.subnet_public_id_1a
    security_groups = [module.security_group.public_sg_id]
    iam_instance_profile = module.iam.iam_instance_profile
}

module "iam" { 
    source = "../../modules/iam"
    env = var.env
    project_name = var.project_name
}