#------------------------------------------------------------------------------
# VPC Module - Network Foundation for Coder Simulation
#
# Architecture:
# - Public subnets (Untrusted Zone): Internet-facing resources, Windows client
# - Private subnets (Trusted Zone): EKS nodes, Coder workloads
# - NAT Gateway: Allows private subnet egress without direct internet exposure
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# VPC
#------------------------------------------------------------------------------

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # Required for EKS
  enable_dns_support   = true  # Required for EKS

  tags = {
    Name = "${var.environment}-vpc"
  }
}

#------------------------------------------------------------------------------
# Internet Gateway - Entry point for untrusted zone
#------------------------------------------------------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

#------------------------------------------------------------------------------
# Public Subnets (Untrusted Zone)
# - Hosts: Windows client, NAT Gateway, Load Balancers
# - Direct internet access via Internet Gateway
#------------------------------------------------------------------------------

resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)  # 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                          = "${var.environment}-public-${var.availability_zones[count.index]}"
    "kubernetes.io/role/elb"                      = "1"  # EKS uses this to place public LBs
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    Zone                                          = "untrusted"
  }
}

#------------------------------------------------------------------------------
# Private Subnets (Trusted Zone)
# - Hosts: EKS nodes, Coder server, Coder workspaces
# - Internet access only via NAT Gateway (egress only)
#------------------------------------------------------------------------------

resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 11)  # 10.0.11.0/24, 10.0.12.0/24, 10.0.13.0/24
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                                          = "${var.environment}-private-${var.availability_zones[count.index]}"
    "kubernetes.io/role/internal-elb"             = "1"  # EKS uses this to place internal LBs
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    Zone                                          = "trusted"
  }
}

#------------------------------------------------------------------------------
# NAT Gateway - Single NAT for cost savings in simulation
# Provides egress for private subnets (pull images, updates, etc.)
#------------------------------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.environment}-nat-eip"
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id  # Place in first public subnet

  tags = {
    Name = "${var.environment}-nat"
  }

  depends_on = [aws_internet_gateway.main]
}

#------------------------------------------------------------------------------
# Route Tables
#------------------------------------------------------------------------------

# Public route table - routes to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-public-rt"
    Zone = "untrusted"
  }
}

# Private route table - routes to NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.environment}-private-rt"
    Zone = "trusted"
  }
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
