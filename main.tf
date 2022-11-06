
data "aws_eip" "by_filter" {
  filter {
    name   = "tag:Name"
    values = ["terraformProject-elasticIP"]
  }
}
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # Internal domain name
  enable_dns_hostnames = true # Internal host name

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public-subnet" {
  # Number of public subnet is defined in vars
  for_each = var.public_prefix
 
  availability_zone = each.value["az"]
  cidr_block        = each.value["cidr"]
  vpc_id            = aws_vpc.main.id

  map_public_ip_on_launch = true # This makes the subnet public

  tags = {
    Name = "${var.project_name}-public-subnet-${each.key}"
  }
 
}

resource "aws_subnet" "private-subnet" {
  # Number of private subnet is defined in vars
  for_each = var.private_prefix
 
  availability_zone = each.value["az"]
  cidr_block        = each.value["cidr"]
  vpc_id            = aws_vpc.main.id


  tags = {
    Name = "${var.project_name}-public-subnet-${each.key}"
  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-internet-gateway"
  }
}

resource "aws_nat_gateway" "nat-gateway" {
  
  allocation_id = data.aws_eip.by_filter.id #variable'a yaz data source type
  subnet_id     = aws_subnet.public-subnet["sub-1"].id
  #"${element(aws_subnet.terraformProject_public_subnet.*.id, 0)}"

  tags = {
    Name = "${var.project_name}-gw-NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.internet-gateway]
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id

  route {
    # Associated subet can reach public internet
    cidr_block = "0.0.0.0/0"

    # Which internet gateway to use
    gateway_id = aws_internet_gateway.internet-gateway.id
  }


  tags = {
    Name = "${var.project_name}-public-custom-rtb"
  }
}

resource "aws_default_route_table" "route_table_private" {
  default_route_table_id = aws_vpc.main.default_route_table_id
  #vpc_id = aws_vpc.main.id

   route {
    cidr_block = "0.0.0.0/0"
    # Which internet gateway to use
    nat_gateway_id = aws_nat_gateway.nat-gateway.id
  }


  tags = {
    Name = "${var.project_name}-private-custom-rtb"
  }
}


resource "aws_route_table_association" "custom-rtb-public-subnet" {
  for_each = var.public_prefix
  route_table_id = aws_route_table.route_table.id
  subnet_id      = aws_subnet.public-subnet[each.key].id
  #nat_gateway_id
}



resource "aws_route_table_association" "custom-rtb-private-subnet" {
  for_each = var.private_prefix
  route_table_id = aws_default_route_table.route_table_private.id
  subnet_id      = aws_subnet.private-subnet[each.key].id
}

resource "aws_security_group" "main-sg" {
  name = "main-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# INSTANCE
resource "aws_instance" "public-instance" {
  ami           = data.aws_ami.aws-linux.id
  instance_type = "t3.micro"
  key_name      = var.ssh_key_name
  
  subnet_id     = aws_subnet.public-subnet["sub-1"].id
  vpc_security_group_ids = [aws_security_group.main-sg.id]

    connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }


  tags = {Environment = "${var.project_name}-test", Name = "${var.project_name}-public-instance"}

}

resource "aws_instance" "private-instance" {
  ami           = data.aws_ami.aws-linux.id
  instance_type = "t3.micro"
  key_name      = var.ssh_key_name
  
  subnet_id     = aws_subnet.private-subnet["sub-1"].id
  vpc_security_group_ids = [aws_security_group.main-sg.id]

    connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_path)
  }


  tags = {Environment = "${var.project_name}-private-test", Name = "${var.project_name}-private-instance"}

}

data "aws_ami" "aws-linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-hvm*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


