
resource "aws_db_subnet_group" "subnet_group" {
  name       = "${var.project_name}-${var.env}-rds-sg"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.project_name}-${var.env}-rds-sg"
  }
}

resource "aws_db_parameter_group" "parameter_group" {
  name   = "${var.project_name}-${var.env}-rds-pg"
  family = "mysql8.4"

  dynamic "parameter" {
    for_each = var.rds_parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = {
    Name = "${var.project_name}-${var.env}-rds-pg"
  }
}

resource "aws_db_option_group" "option_group" {
  name                 = "${var.project_name}-${var.env}-rds-og"
  engine_name          = var.engine
  major_engine_version = 8.4

  tags = {
    Name = "${var.project_name}-${var.env}-rds-og"
  }
}

// パスワード生成
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project_name}-${var.env}-rds-password"
  description = "RDS password for ${var.project_name}"

  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-${var.env}-rds-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.password.result
  })
}

resource "aws_db_instance" "instance" {
  identifier          = "${var.project_name}-${var.env}-rds"
  engine              = var.engine
  engine_version      = var.engine_version
  instance_class      = var.instance_class
  allocated_storage   = 20
  storage_type        = "gp3"
  deletion_protection = var.deletion_protection
  storage_encrypted   = true

  db_name  = var.db_name
  username = var.username
  // manage_master_user_password = true
  password = random_password.password.result

  db_subnet_group_name = aws_db_subnet_group.subnet_group.name
  parameter_group_name = aws_db_parameter_group.parameter_group.name
  option_group_name    = aws_db_option_group.option_group.name

  vpc_security_group_ids     = var.vpc_security_group_ids
  skip_final_snapshot        = true
  auto_minor_version_upgrade = false

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  performance_insights_enabled    = false // instance sizaによる

  apply_immediately = true

  lifecycle {
    ignore_changes = [password]
  }

  tags = {
    Name = "${var.project_name}-${var.env}-rds"
  }
}

output "db_secret_arn" {
  value = aws_secretsmanager_secret.db_password.arn
}



