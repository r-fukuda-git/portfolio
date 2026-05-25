resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name      = "${var.project_name}-${var.env}-nat-eip"
    ManagedBy = "terraform"
  }

}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name      = "${var.project_name}-${var.env}-nat-${var.availability_zone_suffix}"
    ManagedBy = "terraform"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = var.route_cidr_block
  nat_gateway_id         = aws_nat_gateway.nat.id
}
