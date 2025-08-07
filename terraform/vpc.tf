resource "aws_vpc" "photo_gallery_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

resource "aws_internet_gateway" "photo_gallery_igw" {
  vpc_id = aws_vpc.photo_gallery_vpc.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

resource "aws_route_table" "photo_gallery_public_rt" {
  vpc_id = aws_vpc.photo_gallery_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.photo_gallery_igw.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

resource "aws_subnet" "photo_gallery_public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.photo_gallery_vpc.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true # Public subnets need public IPs

  tags = {
    Name                                = "${var.cluster_name}-public-subnet-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" # Tag for EKS to discover
    "kubernetes.io/role/elb"            = "1"             # Tag for ALB Ingress Controller
  }
}

resource "aws_route_table_association" "photo_gallery_public_rt_assoc" {
  count          = length(aws_subnet.photo_gallery_public_subnets)
  subnet_id      = aws_subnet.photo_gallery_public_subnets[count.index].id
  route_table_id = aws_route_table.photo_gallery_public_rt.id
}

resource "aws_subnet" "photo_gallery_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.photo_gallery_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name                                = "${var.cluster_name}-private-subnet-${count.index}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" # Tag for EKS to discover
    "kubernetes.io/role/internal-elb"   = "1"             # Tag for internal ALBs (if needed)
  }
}

# Create NAT Gateways for private subnets to access the internet (e.g., ECR, S3 endpoints)
resource "aws_eip" "photo_gallery_nat_eip" {
  count = length(var.private_subnet_cidrs) # One NAT Gateway per private subnet's AZ
  #vpc   = true
  tags = {
    Name = "${var.cluster_name}-nat-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "photo_gallery_nat_gateway" {
  count         = length(var.private_subnet_cidrs)
  allocation_id = aws_eip.photo_gallery_nat_eip[count.index].id
  subnet_id     = aws_subnet.photo_gallery_public_subnets[count.index].id # NAT Gateway in public subnet

  tags = {
    Name = "${var.cluster_name}-nat-gateway-${count.index}"
  }
}

resource "aws_route_table" "photo_gallery_private_rt" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.photo_gallery_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.photo_gallery_nat_gateway[count.index].id
  }

  tags = {
    Name = "${var.cluster_name}-private-rt-${count.index}"
  }
}

resource "aws_route_table_association" "photo_gallery_private_rt_assoc" {
  count          = length(aws_subnet.photo_gallery_private_subnets)
  subnet_id      = aws_subnet.photo_gallery_private_subnets[count.index].id
  route_table_id = aws_route_table.photo_gallery_private_rt[count.index].id
}
