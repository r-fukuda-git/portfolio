data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

module "ecr" {
  source = "../../../modules/ecr"

  env                  = var.env
  project_name         = var.project_name
  repository_suffix    = var.repository_suffix
  scan_on_push         = var.ecr_scan_on_push
  image_tag_mutability = var.image_tag_mutability
  lifecycle_policy     = var.lifecycle_policy
}

# プライベートサブネット上の ECS が NAT なしで ECR からイメージ取得できるようにする
module "vpc_endpoints_ecs" {
  source = "../../../modules/vpc_endpoints_ecs"

  env          = var.env
  project_name = var.project_name

  vpc_id = data.terraform_remote_state.network.outputs.vpc_id
  subnet_ids = [
    data.terraform_remote_state.network.outputs.subnet_private_id_1a,
    data.terraform_remote_state.network.outputs.subnet_private_id_1c,
  ]
  private_route_table_ids = [
    data.terraform_remote_state.network.outputs.private_route_table_id,
  ]
}
