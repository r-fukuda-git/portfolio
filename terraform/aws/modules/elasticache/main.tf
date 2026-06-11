resource "aws_security_group" "cache" {
  name   = "${var.project_name}-${var.env}-cache-sg"
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.project_name}-${var.env}-cache-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_cache" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.cache.id
  description              = "Allow cache access from client security groups"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.cache.id
  description       = "All"
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.project_name}-${var.env}-cache-subnet"
  subnet_ids = var.subnet_ids

  tags = {
    Name      = "${var.project_name}-${var.env}-cache-subnet"
    ManagedBy = "terraform"
  }
}

resource "aws_elasticache_parameter_group" "this" {
  name   = "${var.project_name}-${var.env}-cache-pg"
  family = var.parameter_group_family

  tags = {
    Name      = "${var.project_name}-${var.env}-cache-pg"
    ManagedBy = "terraform"
  }
}

resource "aws_elasticache_cluster" "this" {
  # Node-based (non-serverless) single-node cluster in private subnets
  cluster_id           = "${var.project_name}-${var.env}-cache"
  engine               = var.engine
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  port                 = var.port
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  parameter_group_name = aws_elasticache_parameter_group.this.name
  security_group_ids   = [aws_security_group.cache.id]

  tags = {
    Name      = "${var.project_name}-${var.env}-cache"
    ManagedBy = "terraform"
  }
}
