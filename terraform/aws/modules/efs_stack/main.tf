locals {
  efs_name    = "${var.project_name}-${var.env}-efs"
  efs_sg_name = "${var.project_name}-${var.env}-efs-sg"
}

data "aws_resourcegroupstaggingapi_resources" "existing_efs" {
  resource_type_filters = ["elasticfilesystem:file-system"]
  tag_filter {
    key    = "Name"
    values = [local.efs_name]
  }
}

locals {
  efs_exists = length(data.aws_resourcegroupstaggingapi_resources.existing_efs.resource_tag_mapping_list) > 0
  existing_efs_id = local.efs_exists ? regex(
    ":file-system/(.+)$",
    data.aws_resourcegroupstaggingapi_resources.existing_efs.resource_tag_mapping_list[0].resource_arn
  )[0] : null
}

module "efs" {
  count  = local.efs_exists ? 0 : 1
  source = "../efs"

  project_name               = var.project_name
  env                        = var.env
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.subnet_ids
  allowed_security_group_ids = var.client_security_group_ids
  expected_storage_gb        = var.expected_storage_gb
  performance_mode           = var.performance_mode
  throughput_mode            = var.throughput_mode
}

data "aws_efs_file_system" "existing" {
  count          = local.efs_exists ? 1 : 0
  file_system_id = local.existing_efs_id
}

data "aws_resourcegroupstaggingapi_resources" "existing_efs_sg" {
  count = local.efs_exists ? 1 : 0

  resource_type_filters = ["ec2:security-group"]
  tag_filter {
    key    = "Name"
    values = [local.efs_sg_name]
  }
}

locals {
  existing_efs_sg_arn = local.efs_exists ? data.aws_resourcegroupstaggingapi_resources.existing_efs_sg[0].resource_tag_mapping_list[0].resource_arn : null
  efs_security_group_id = local.efs_exists ? regex(":security-group/(.+)$", local.existing_efs_sg_arn)[0] : module.efs[0].security_group_id
}

# 先に apply したスタックが EFS 本体を作る。後から apply する側は NFS 用 SG ルールだけ追加する
resource "aws_security_group_rule" "client_nfs" {
  for_each = local.efs_exists ? toset(var.client_security_group_ids) : toset([])

  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = local.efs_security_group_id
  description              = "Allow NFS from client security groups"
}
