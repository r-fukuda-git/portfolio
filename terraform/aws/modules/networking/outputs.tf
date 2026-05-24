output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_public_id_1a" {
  value = aws_subnet.public_subnet_1a.id
}

output "subnet_public_id_1c" {
  value = aws_subnet.public_subnet_1c.id
}

output "subnet_private_id_1a" {
  value = aws_subnet.private_subnet_1a.id
}

output "subnet_private_id_1c" {
  value = aws_subnet.private_subnet_1c.id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}

output "nat_eip_public_ip" {
  value = aws_eip.nat.public_ip
}
