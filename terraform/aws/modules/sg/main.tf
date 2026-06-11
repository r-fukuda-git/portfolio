locals {
  # 重複 CIDR は AWS API が拒否するため plan/apply 前に除去
  source_cidr_blocks = distinct(var.source_cidr_blocks)
  target_cidr_blocks = distinct(var.target_cidr_blocks)

  create_web_sg = var.create_web_and_db_security_groups || var.create_web_security_group
  create_db_sg  = var.create_web_and_db_security_groups || var.create_db_security_group

  # db SG のみ別スタックで作る場合は EC2 等の web SG を外部参照する
  db_ingress_source_security_group_id = var.create_web_and_db_security_groups ? aws_security_group.web_public[0].id : var.db_ingress_source_security_group_id
}

resource "aws_security_group" "web_public" {
  count = local.create_web_sg ? 1 : 0

  name   = "${var.project_name}-${var.env}-web-sg"
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.project_name}-${var.env}-web-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_allow_http" {
  count = local.create_web_sg ? 1 : 0

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.web_public[0].id
  description       = "Allow HTTP"
}

resource "aws_security_group_rule" "ingress_allow_https" {
  count = local.create_web_sg ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.web_public[0].id
  description       = "Allow HTTPS"
}

resource "aws_security_group_rule" "ingress_allow_ssh" {
  count = local.create_web_sg ? 1 : 0

  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.web_public[0].id
  description       = "Allow SSH"
}

resource "aws_security_group_rule" "egress_all" {
  count = local.create_web_sg ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.target_cidr_blocks
  security_group_id = aws_security_group.web_public[0].id
  description       = "All"
}

output "public_sg_id" {
  value = local.create_web_sg ? aws_security_group.web_public[0].id : null
}

resource "aws_security_group" "db_private" {
  count = local.create_db_sg ? 1 : 0

  name   = "${var.project_name}-${var.env}-db-sg"
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.project_name}-${var.env}-db-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_allow_web_sg" {
  count = local.create_db_sg ? 1 : 0

  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = local.db_ingress_source_security_group_id
  security_group_id        = aws_security_group.db_private[0].id
  description              = "Allow WebSG"
}

output "private_sg_id" {
  value = local.create_db_sg ? aws_security_group.db_private[0].id : null
}

resource "aws_security_group" "ecs_sg" {
  count = var.create_ecs_and_alb_security_groups ? 1 : 0

  name   = "${var.project_name}-${var.env}-ecs-sg"
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.project_name}-${var.env}-ecs-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group" "alb" {
  count = var.create_ecs_and_alb_security_groups ? 1 : 0

  name   = "${var.project_name}-${var.env}-alb-sg"
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.project_name}-${var.env}-alb-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_allow_http_alb" {
  count = var.create_ecs_and_alb_security_groups ? 1 : 0

  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow HTTP to ALB"
}

resource "aws_security_group_rule" "ingress_allow_https_alb" {
  count = var.create_ecs_and_alb_security_groups ? 1 : 0

  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = local.source_cidr_blocks
  security_group_id = aws_security_group.alb[0].id
  description       = "Allow HTTPS to ALB"
}

resource "aws_security_group_rule" "egress_all_alb" {
  count = var.create_ecs_and_alb_security_groups ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.target_cidr_blocks
  security_group_id = aws_security_group.alb[0].id
  description       = "All"
}

output "alb_sg_id" {
  value = var.create_ecs_and_alb_security_groups ? aws_security_group.alb[0].id : null
}

resource "aws_security_group_rule" "ingress_allow_alb_to_ecs" {
  count = var.create_ecs_and_alb_security_groups ? 1 : 0

  type                     = "ingress"
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb[0].id
  security_group_id        = aws_security_group.ecs_sg[0].id
  description              = "Allow traffic from ALB"
}

resource "aws_security_group_rule" "egress_all_ecs" {
  count = var.create_ecs_and_alb_security_groups ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = local.target_cidr_blocks
  security_group_id = aws_security_group.ecs_sg[0].id
  description       = "All"
}

output "private_ecs_sg_id" {
  value = var.create_ecs_and_alb_security_groups ? aws_security_group.ecs_sg[0].id : null
}
