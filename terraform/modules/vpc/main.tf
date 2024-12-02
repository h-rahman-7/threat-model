## My VPC
resource "aws_vpc" "tm_vpc" {
  cidr_block           = var.vpc_cidr   # The size of your network (larger than one below 2^16)
  enable_dns_support   = true            # Helps services find each other using names
  enable_dns_hostnames = true            # Allows human-readable names like "myapp.com"
  tags = {
    Name = var.vpc_name                      # The name/tag you give your VPC
  }
}

## My subnets
resource "aws_subnet" "tm_public_sn" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.tm_vpc.id                        # Attach this public subnet to your VPC
  cidr_block              = var.public_subnet_cidrs[count.index]     # A smaller range of IPs (256 addresses 2^8) for public use
  map_public_ip_on_launch = true                                     # Public IPs for resources in this subnet
  availability_zone       = var.availability_zones[count.index]      # Place this subnet in a specific AWS data center
  tags = {
    Name = "${var.vpc_name}-public-${count.index + 1}"               # Name the subnet
  }
}

resource "aws_subnet" "tm_private_sn" {
  vpc_id            = aws_vpc.tm_vpc.id
  cidr_block        = "10.0.3.0/24"                                  # Another range of IPs for private use
  availability_zone = "us-east-1b"
  tags = {
    Name = "tm-private-sn"
  }
}

## My internet gateway
resource "aws_internet_gateway" "tm_igw" {
  vpc_id = aws_vpc.tm_vpc.id
  tags = {
    Name = "$(var.vpc_name)-igw"
  }
}

## My application security group
resource "aws_security_group" "tm_sg" {
  vpc_id = aws_vpc.tm_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows HTTP from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows HTTPS from anywhere
  }

  ingress {
    from_port   = 3001           # Forwarding requests to ECS container
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"           # Allows all outgoing traffic   
    cidr_blocks = ["0.0.0.0/0"]  
  }

  tags = {
    Name = "tm-sg"
  }
}

## My route table
resource "aws_route_table" "tm_rt" {
  vpc_id = aws_vpc.tm_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tm_igw.id
  }

  tags = {
    Name = "${var.vpc_name}}-rt"
  }
}

## My route table association
resource "aws_route_table_association" "tm_subnet_rt_assoc" {
  count = length(aws_subnet.tm_public_sn)
  subnet_id      = aws_subnet.tm_public_sn[count.index].id
  route_table_id = aws_route_table.tm_rt.id
}

## My ACM certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = "ecs.habibur-rahman.com"  
  validation_method = "DNS"                      
  tags = {
    Name = "ecs-cert"
  }
}


