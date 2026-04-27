module "rds" {
  source                  = "../../../modules/rds"
  project_name            = var.project_name
  env                     = var.env
  subnet_ids              = [module.networking.subnet_private_id_1a, module.networking.subnet_private_id_1c]
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