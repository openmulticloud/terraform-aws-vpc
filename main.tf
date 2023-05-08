resource "aws_vpc" "vpc_1" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    "Name" = "vpc-1"
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet)

  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = var.private_subnet[count.index]
  //availability_zone = var.availability_zone[count.index % length(var.availability_zone)]
  availability_zone = var.availability_zone[count.index]

  tags = {
    "Name" = "private-subnet"
  }
}

resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet)

  vpc_id            = aws_vpc.vpc_1.id
  cidr_block        = var.public_subnet[count.index]
  //availability_zone = var.availability_zone[count.index % length(var.availability_zone)]
  availability_zone = var.availability_zone[count.index]

  tags = {
    "Name" = "public-subnet"
  }
}

resource "aws_internet_gateway" "internet_gateway_1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    "Name" = "internet-gateway-1"
  }
}

resource "aws_route_table" "route_table_public_1" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway_1.id
  }

  tags = {
    "Name" = "route-table-public-1"
  }
}

resource "aws_route_table_association" "public_association" {
  for_each       = { for k, v in aws_subnet.public_subnet : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.route_table_public_1.id
}

resource "aws_eip" "eip_1" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway_1" {
  depends_on = [aws_internet_gateway.internet_gateway_1]

  allocation_id = aws_eip.eip_1.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = {
    Name = "nat-gateway-1"
  }
}

resource "aws_route_table" "route_table_private_1" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway_1.id
  }

  tags = {
    "Name" = "route-table-private-1"
  }
}

resource "aws_route_table_association" "route_table_association_private" {
  for_each       = { for k, v in aws_subnet.private_subnet : k => v }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.route_table_private_1.id
}
