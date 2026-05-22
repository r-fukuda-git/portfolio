resource "aws_security_group" "web_public" {
  name   = "${var.project_name}-${var.env}-web-sg"
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.project_name}-${var.env}-web-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_allow_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.source_cidr_blocks
  security_group_id = aws_security_group.web_public.id
  description       = "Allow HTTP"
}

resource "aws_security_group_rule" "ingress_allow_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.source_cidr_blocks
  security_group_id = aws_security_group.web_public.id
  description       = "Allow HTTPS"
}

resource "aws_security_group_rule" "ingress_allow_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.source_cidr_blocks
  security_group_id = aws_security_group.web_public.id
  description       = "Allow SSH"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.target_cidr_blocks
  security_group_id = aws_security_group.web_public.id
  description       = "All"
}

output "public_sg_id" {
  value = aws_security_group.web_public.id
}

resource "aws_security_group" "db_private" {
  name   = "${var.project_name}-${var.env}-db-sg"
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.project_name}-${var.env}-db-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_allow_web_sg" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_public.id
  security_group_id        = aws_security_group.db_private.id
  description              = "Allow WebSG"
}

output "private_sg_id" {
  value = aws_security_group.db_private.id
}

resource "aws_security_group" "ecs_sg" {
  name   = "${var.project_name}-${var.env}-ecs-sg"
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.project_name}-${var.env}-ecs-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group" "alb" {
  name   = "${var.project_name}-${var.env}-alb-sg"
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.project_name}-${var.env}-alb-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_allow_http_alb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.source_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP to ALB"
}

resource "aws_security_group_rule" "ingress_allow_https_alb" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.source_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS to ALB"
}

resource "aws_security_group_rule" "egress_all_alb" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.target_cidr_blocks
  security_group_id = aws_security_group.alb.id
  description       = "All"
}

output "alb_sg_id" {
  value = aws_security_group.alb.id
}

resource "aws_security_group_rule" "ingress_allow_alb_to_ecs" {
  type                     = "ingress"
  from_port                = var.ecs_container_port
  to_port                  = var.ecs_container_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.ecs_sg.id
  description              = "Allow traffic from ALB"
}

resource "aws_security_group_rule" "egress_all_ecs" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = var.target_cidr_blocks
  security_group_id = aws_security_group.ecs_sg.id
  description       = "All"
}

output "private_ecs_sg_id" {
  value = aws_security_group.ecs_sg.id
}
