# VPC
resource "aws_vpc" "rgs_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "dev"
  }
}

# Public Subnet
resource "aws_subnet" "rgs_public_subnet" {
  vpc_id                  = aws_vpc.rgs_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "dev-public"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "rgs_internet_gateway" {
  vpc_id = aws_vpc.rgs_vpc.id

  tags = {
    Name = "dev-igw"
  }
}

# Route Table
resource "aws_route_table" "rgs_public_rt" {
  vpc_id = aws_vpc.rgs_vpc.id

  tags = {
    Name = "dev-public-rt"
  }
}

# Route
resource "aws_route" "rgs_default_route" {
  route_table_id         = aws_route_table.rgs_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.rgs_internet_gateway.id
}

# Route Table Association
resource "aws_route_table_association" "rgs_public_assoc" {
  subnet_id      = aws_subnet.rgs_public_subnet.id
  route_table_id = aws_route_table.rgs_public_rt.id
}

# Security Group
resource "aws_security_group" "rgs_sg" {
  name        = "dev-sg"
  description = "Dev Security Group"
  vpc_id      = aws_vpc.rgs_vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["89.187.185.185/32"]
    #cidr_blocks = [0.0.0.0/0 ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Key Pair
resource "aws_key_pair" "rgs_auth" {
  key_name   = "rgskey"
  public_key = file ("~/.ssh/rgskey.pub")
}

# AWS Instance
resource "aws_instance" "dev-node" {
  instance_type = "t2.micro"
  ami = data.aws_ami.rgs_data.id
  key_name = aws_key_pair.rgs_auth.id
  vpc_security_group_ids = [aws_security_group.rgs_sg.id]
  subnet_id = aws_subnet.rgs_public_subnet.id
  user_data = file("userdata.tpl")

  tags = {
    Name = "dev-node"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname = self.public_ip,
      user = "ubuntu",
      identityfile = "~/.ssh/rgskey"
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]

  } 
}

