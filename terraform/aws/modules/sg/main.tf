resource "aws_security_group" "web_public" {
  name = "${var.project_name}-${var.env}-web-sg"
  vpc_id = modules.networking.vpc_id

  tags = {
    Name = "${var.project_name}-${var.env}-web-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_allow_http" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = var.source_cidr_blocks
  security_group_id = aws_security_group.web_public.id
  description = "Allow HTTP"
}

resource "aws_security_group_rule" "ingress_allow_https" {
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = var.source_cidr_blocks
  security_group_id = aws_security_group.web_public.id
  description = "Allow HTTPS"
}

resource "aws_security_group_rule" "ingress_allow_ssh" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = var.source_cidr_blocks
  security_group_id = aws_security_group.web_public.id
  description = "Allow SSH"
}

output public_sg_id {
  value       = aws_security_group.web_public.id
  sensitive   = true
  description = "description"
  depends_on  = []
}