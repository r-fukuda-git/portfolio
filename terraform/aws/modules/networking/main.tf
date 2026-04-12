
# VPC設定
resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block_vpc
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.project_name}-${var.env}-vpc"
    ManagedBy = "terraform"
  }
}

output vpc_id {
  value = aws_vpc.vpc.id
}

# サブネット設定
resource "aws_subnet" "public_subnet_1a" {
    vpc_id = module.networking.vpc_id
    cidr_block = var.public_subnet_1a
    availability_zone = "ap-northeast-1a"

    tags = {
        Name = "${var.project_name}-${var.env}-public-1a"
        ManagedBy = "terraform"
    }
}

resource "aws_subnet" "public_subnet_1c" {
    vpc_id = module.networking.vpc_id
    cidr_block = var.public_subnet_1c
    availability_zone = "ap-northeast-1c"

    tags = {
        Name = "${var.project_name}-${var.env}-public-1c"
        ManagedBy = "terraform"
    }
}

resource "aws_subnet" "private_subnet_1a" {
    vpc_id = module.networking.vpc_id
    cidr_block = var.private_subnet_1a
    availability_zone = "ap-northeast-1a"

    tags = {
        Name = "${var.project_name}-${var.env}-private-1a"
        ManagedBy = "terraform"
    }
}

resource "aws_subnet" "private_subnet_1c" {
    vpc_id = module.networking.vpc_id
    cidr_block = var.private_subnet_1c
    availability_zone = "ap-northeast-1c"

    tags = {
        Name = "${var.project_name}-${var.env}-private-1c"
        ManagedBy = "terraform"
    }
}

output subnet_public_id {
  value = module.networking.public_subnet_1[*].id
}

output subnet_private_id {
  value = module.networking.private_subnet_1[*].id
}

# IGWの設定
resource "aws_internet_gateway" "igw" {
  vpc_id = module.networking.vpc_id
  tags = {
    Name = "${var.project_name}-${var.env}-igw"
  }
}

# ルートテーブルの設定
resource "aws_route_table" "public_route" {
  vpc_id = module.networking.vpc_id
  route {
    cidr_block = var.route_cidr_block
    gateway_id = aws_internet_gateway.igw.id
  }

  tags {
    Name = "${var.project_name}-${var.env}-public-rt"
  }
}

resource "aws_route_table" "private_route" {
  vpc_id = module.networking.vpc_id

  tags {
    Name = "${var.project_name}-${var.env}-private-rt"
  }
}

# ルートテーブルとサブネットの関連付け設定
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public_subnet_1[*].id
  route_table_id =  aws_route_table.public_route.id
}

resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private_subnet_1[*].id
  route_table_id = aws_route_table.private_route.id
}