data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

data "terraform_remote_state" "database" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.database
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

module "efs" {
  source       = "../../../modules/efs"
  project_name = var.project_name
  env          = var.env

  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  # EC2 と同一 AZ のマウントターゲットをパブリックサブネットに配置
  subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_public_id_1a,
    data.terraform_remote_state.network.outputs.subnet_public_id_1c
  ]
  allowed_security_group_ids = compact([
    data.terraform_remote_state.database.outputs.public_security_group_id,
    data.terraform_remote_state.compute_ec2.outputs.web_security_group_id,
    data.terraform_remote_state.compute_ecs.outputs.ecs_security_group_id,
  ])

  expected_storage_gb = var.expected_storage_gb
  performance_mode    = var.performance_mode
  throughput_mode     = var.throughput_mode
}
