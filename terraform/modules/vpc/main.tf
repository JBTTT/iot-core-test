resource "aws_vpc" "main" {
  cidr_block           = "10.${var.env == "dev" ? 10 : 20}.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.prefix}-${var.env}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.prefix}-${var.env}-igw" }
}

# Public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.${var.env == "dev" ? 10 : 20}.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}a"
  tags                    = { Name = "${var.prefix}-${var.env}-public-subnet" }
}

# Private subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.${var.env == "dev" ? 10 : 20}.2.0/24"
  availability_zone = "${var.region}a"
  tags              = { Name = "${var.prefix}-${var.env}-private-subnet" }
}

# Public route table -> IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.prefix}-${var.env}-public-rt" }
}

resource "aws_route" "public_default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# NAT for private subnet egress
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.prefix}-${var.env}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "${var.prefix}-${var.env}-nat" }
}

# Private route table -> NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.prefix}-${var.env}-private-rt" }
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security group (you can tighten later)
resource "aws_security_group" "main_sg" {
  vpc_id = aws_vpc.main.id
  name   = "${var.prefix}-${var.env}-sg"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.prefix}-${var.env}-sg" }
}
