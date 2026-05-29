data "aws_region" "current" {}

data "aws_vpc" "this" {
  id = var.vpc_id
}

# Interface endpoint への HTTPS を VPC 内から許可する
resource "aws_security_group" "endpoint" {
  name   = "${var.project_name}-${var.env}-vpc-endpoint-sg"
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.project_name}-${var.env}-vpc-endpoint-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_https_from_vpc" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.this.cidr_block]
  security_group_id = aws_security_group.endpoint.id
  description       = "HTTPS from VPC for ECS/ECR endpoints"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.endpoint.id
  description       = "All"
}

locals {
  # Fargate がプライベートサブネットで ECR イメージ取得・タスク実行するために必要な最小構成
  interface_endpoints = {
    ecr_api = "ecr.api"
    ecr_dkr = "ecr.dkr"
    logs    = "logs"
    ecs     = "ecs"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = [aws_security_group.endpoint.id]
  private_dns_enabled = true

  tags = {
    Name      = "${var.project_name}-${var.env}-${each.key}-endpoint"
    ManagedBy = "terraform"
  }
}

# ECR イメージレイヤ取得用（Gateway endpoint）
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = {
    Name      = "${var.project_name}-${var.env}-s3-endpoint"
    ManagedBy = "terraform"
  }
}
