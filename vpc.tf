## My VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"   # The size of your network
  enable_dns_support   = true            # Helps services find each other using names
  enable_dns_hostnames = true            # Allows human-readable names like "myapp.com"
  tags = {
    Name = "ecs-threat-model-vpc"                  # A friendly name for your VPC
  }
}

## My subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id    # Attach this subnet to the VPC
  cidr_block              = "10.0.1.0/24"     # A smaller range of IPs (254 addresses)
  map_public_ip_on_launch = true              # Public IPs for resources in this subnet
  availability_zone       = "us-east-1a"      # Place this subnet in a specific AWS data center
  tags = {
    Name = "public-subnet"                    # Name the subnet
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"           # Another range of IPs for private use
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet"
  }
}

## My internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "my-internet-gateway"
  }
}

