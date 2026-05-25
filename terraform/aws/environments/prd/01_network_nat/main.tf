data "terraform_remote_state" "network" {
  backend = "s3"
  config = merge(local.terraform_remote_state_base, {
    key = local.terraform_state_key.network
  })
}

module "nat_gateway" {
  source = "../../../modules/nat_gateway"

  env                      = var.env
  project_name             = var.project_name
  route_cidr_block         = var.route_cidr_block
  availability_zone_suffix = var.availability_zone_suffix

  public_subnet_id         = data.terraform_remote_state.network.outputs.subnet_public_id_1a
  private_route_table_id   = data.terraform_remote_state.network.outputs.private_route_table_id
}
