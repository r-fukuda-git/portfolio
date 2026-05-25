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

output "private_route_table_id" {
  value = aws_route_table.private_route.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}
