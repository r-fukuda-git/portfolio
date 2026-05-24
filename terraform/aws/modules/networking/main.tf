
# VPC設定
resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name      = "${var.project_name}-${var.env}-vpc"
    ManagedBy = "terraform"
  }
}

# サブネット設定
resource "aws_subnet" "public_subnet_1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_1a
  availability_zone = "ap-northeast-1a"

  tags = {
    Name      = "${var.project_name}-${var.env}-public-1a"
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "public_subnet_1c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_1c
  availability_zone = "ap-northeast-1c"

  tags = {
    Name      = "${var.project_name}-${var.env}-public-1c"
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "private_subnet_1a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_1a
  availability_zone = "ap-northeast-1a"

  tags = {
    Name      = "${var.project_name}-${var.env}-private-1a"
    ManagedBy = "terraform"
  }
}

resource "aws_subnet" "private_subnet_1c" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnet_1c
  availability_zone = "ap-northeast-1c"

  tags = {
    Name      = "${var.project_name}-${var.env}-private-1c"
    ManagedBy = "terraform"
  }
}

# IGWの設定
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.project_name}-${var.env}-igw"
  }
}

# NAT Gateway（public 1a に配置。コスト優先の単一 NAT。AZ ごとに増やす場合は 1c 用を追加）
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name      = "${var.project_name}-${var.env}-nat-eip"
    ManagedBy = "terraform"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_subnet_1a.id

  tags = {
    Name      = "${var.project_name}-${var.env}-nat-1a"
    ManagedBy = "terraform"
  }

  depends_on = [aws_internet_gateway.igw]
}

# ルートテーブルの設定
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = var.route_cidr_block
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-${var.env}-public-rt"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.project_name}-${var.env}-private-rt"
  }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private_route.id
  destination_cidr_block = var.route_cidr_block
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# ルートテーブルとサブネットの関連付け設定
resource "aws_route_table_association" "public-1a" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "public-1c" {
  subnet_id      = aws_subnet.public_subnet_1c.id
  route_table_id = aws_route_table.public_route.id
}

resource "aws_route_table_association" "private-1a" {
  subnet_id      = aws_subnet.private_subnet_1a.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route_table_association" "private-1c" {
  subnet_id      = aws_subnet.private_subnet_1c.id
  route_table_id = aws_route_table.private_route.id
}