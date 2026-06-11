data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

data "terraform_remote_state" "compute_ec2" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.compute_ec2
  })
}

data "terraform_remote_state" "compute_ecs" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.compute_ecs
  })
}

locals {
  # EC2/ECS のどちらか先に apply 済みであれば、その SG を NFS クライアントとして採用する
  client_security_group_ids = compact([
    try(data.terraform_remote_state.compute_ec2.outputs.web_security_group_id, null),
    try(data.terraform_remote_state.compute_ecs.outputs.ecs_security_group_id, null),
  ])
}

check "client_security_groups" {
  assert {
    condition     = length(local.client_security_group_ids) > 0
    error_message = "03_compute_ec2 または 04_compute_ecs を先に apply し、web/ecs security group を state に出力してから 06_efs を実行してください。"
  }
}

module "efs" {
  source = "../../../modules/efs"

  project_name = var.project_name
  env          = var.env
  vpc_id       = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_public_id_1a,
    data.terraform_remote_state.network.outputs.subnet_public_id_1c
  ]
  allowed_security_group_ids = local.client_security_group_ids

  expected_storage_gb = var.expected_storage_gb
  performance_mode    = var.performance_mode
  throughput_mode     = var.throughput_mode
}
