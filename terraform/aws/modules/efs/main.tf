resource "aws_security_group" "efs" {
  name   = "${var.project_name}-${var.env}-efs-sg"
  vpc_id = var.vpc_id

  tags = {
    Name      = "${var.project_name}-${var.env}-efs-sg"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group_rule" "ingress_nfs" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.efs.id
  description              = "Allow NFS from client security groups"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.efs.id
  description       = "All"
}

resource "aws_efs_file_system" "this" {
  # Regional (multi-AZ) standard file system; size grows with usage
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  encrypted        = var.encrypted
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  tags = {
    Name              = "${var.project_name}-${var.env}-efs"
    ManagedBy         = "terraform"
    ExpectedStorageGb = tostring(var.expected_storage_gb)
  }
}

resource "aws_efs_mount_target" "this" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}
