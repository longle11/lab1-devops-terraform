#AWS VPC Resource
resource "aws_vpc" "vpc" {
  cidr_block           = var.use_ipam_pool ? null : var.cidr_block_vpc //check whether users want to use IPAM to manage the range of IPs or not
  enable_dns_hostnames = var.enable_dns_hostnames                      // allows to on or off dns hostname which using to create domain name for ec2 in that vpc
  enable_dns_support   = var.enable_dns_support

  tags = { Environment = var.environment, CreatedBy = var.createdBy }
}


#AWS Internet Gateway
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Environment = var.environment, CreatedBy = var.createdBy }
}

################################################################################
# Publiс Subnets
################################################################################

resource "aws_subnet" "vpc_public_subnet" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr_block
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags = {
    "Name"      = each.key,
    Environment = var.environment,
    CreatedBy   = var.createdBy
  }
}

#AWS Route Table Public
resource "aws_route_table" "vpc_route_table_public" {
  for_each = aws_subnet.vpc_public_subnet
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }
  tags = {
    Environment = var.environment,
    Name        = "public-route-table-${each.key}",
    CreatedBy   = var.createdBy
  }
}

#AWS Routable Association 
resource "aws_route_table_association" "vpc_route_association_public_subnet" {
  for_each       = aws_subnet.vpc_public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.vpc_route_table_public[each.key].id
}

# #AWS Security Group
# resource "aws_security_group" "vpc_security_group" {
#   name   = var.vpc_security_group_name
#   vpc_id = aws_vpc.vpc.id

#   #ssh access from vpc
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Environment = var.environment
#   }
# }
################################################################################
# Nat Gateway
################################################################################
resource "aws_eip" "eip" {
  vpc = var.allow_eip_vpc

  tags = {
    Name        = "nat_eip",
    Environment = var.environment,
    CreatedBy   = var.createdBy
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip.id
  subnet_id     = aws_subnet.vpc_public_subnet[0].id

  tags = {
    Name        = "gateway NAT",
    Environment = var.environment,
    CreatedBy   = var.createdBy
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.vpc_igw]
}

# resource "aws_route_table" "private_instance_to_natgateway" {
#   vpc_id = aws_vpc.vpc.id
#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat_gateway.id
#   }
# }

# resource "aws_route_table_association" "instance" {
#   subnet_id      = aws_subnet.vpc_private_subnet.id
#   route_table_id = aws_route_table.private_instance_to_natgateway.id

#   depends_on = [aws_subnet.vpc_private_subnet]
# }


################################################################################
# Private Subnets
################################################################################

resource "aws_subnet" "vpc_private_subnet" {
  for_each                                    = var.private_subnets
  vpc_id                                      = aws_vpc.vpc.id
  availability_zone                           = each.value.availability_zone
  cidr_block                                  = each.value.cidr_block
  enable_resource_name_dns_a_record_on_launch = var.private_subnets_enable_resource_name_dns_a_record_on_launch
  map_public_ip_on_launch                     = var.map_public_ip_on_launch_private
  tags = {
    "Name"      = each.key,
    Environment = var.environment,
    CreatedBy   = var.createdBy
  }
}

resource "aws_route_table" "vpc_route_table_private" {
  for_each = aws_subnet.vpc_private_subnet
  vpc_id   = aws_vpc.vpc.id
  tags = {
    "Name"      = each.key,
    Environment = var.environment,
    CreatedBy   = var.createdBy
  }
}

resource "aws_route" "vpc_route_private" {
  for_each = aws_route_table.vpc_route_table_private
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
  depends_on             = [aws_route_table.vpc_route_table_private]
}

resource "aws_route_table_association" "vpc_route_association_private_subnet" {
  for_each = aws_subnet.vpc_private_subnet

  subnet_id      = each.value.id
  route_table_id = aws_route_table.vpc_route_table_private[each.key].id
}