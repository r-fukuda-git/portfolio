output "vpc_id" {
  value = module.networking.vpc_id
}

output "subnet_public_id_1a" {
  value = module.networking.subnet_public_id_1a
}

output "subnet_public_id_1c" {
  value = module.networking.subnet_public_id_1c
}

output "subnet_private_id_1a" {
  value = module.networking.subnet_private_id_1a
}

output "subnet_private_id_1c" {
  value = module.networking.subnet_private_id_1c
}

output "nat_gateway_id" {
  value = module.networking.nat_gateway_id
}

output "nat_eip_public_ip" {
  value = module.networking.nat_eip_public_ip
}
