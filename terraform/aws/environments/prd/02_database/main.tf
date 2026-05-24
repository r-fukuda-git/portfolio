data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

module "rds" {
  source       = "../../../modules/rds"
  project_name = var.project_name
  env          = var.env
  subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_private_id_1a,
    data.terraform_remote_state.network.outputs.subnet_private_id_1c
  ]
  vpc_security_group_ids  = [module.security_group.private_sg_id]
  instance_class          = var.instance_class
  engine                  = var.engine
  engine_version          = var.engine_version
  db_name                 = var.db_name
  username                = var.username
  multi_az                = var.multi_az
  deletion_protection     = var.deletion_protection
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window
  backup_retention_period = var.backup_retention_period

}

module "security_group" {
  source             = "../../../modules/sg"
  env                = var.env
  project_name       = var.project_name
  source_cidr_blocks = var.source_cidr_blocks
  target_cidr_blocks = var.target_cidr_blocks

  # Networkレイヤーから取得
  vpc_id = data.terraform_remote_state.network.outputs.vpc_id

  create_web_and_db_security_groups  = true
  create_ecs_and_alb_security_groups = false
}
