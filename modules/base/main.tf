/*====
VPC
======*/

resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.environment}-vpc"
    Environment = var.environment
  }
}

/*====
Subnets
======*/

/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.environment}-igw"
    Environment = var.environment
  }
}

/* Public subnet */
resource "aws_subnet" "public_subnet" {
  vpc_id = aws_vpc.vpc.id
  count = length(var.public_subnets_cidr)
  cidr_block = element(var.public_subnets_cidr, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment}-${element(var.availability_zones, count.index)}-public-subnet"
    Environment = var.environment
  }
}

/* Private subnet */
resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.vpc.id
  count = length(var.private_subnets_cidr)
  cidr_block = element(var.private_subnets_cidr, count.index)
  availability_zone = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment}-${element(var.availability_zones, count.index)}-private-subnet"
    Environment = var.environment
  }
}

/* Routing table for private subnet */
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.environment}-private-route-table"
    Environment = var.environment
  }
}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.environment}-public-route-table"
    Environment = var.environment
  }
}

resource "aws_route" "public_internet_gateway" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ig.id
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  count = length(var.public_subnets_cidr)
  subnet_id = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count = length(var.private_subnets_cidr)
  subnet_id = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private.id
}

/*====
VPC Security Group
======*/
resource "aws_security_group" "default" {
  name = "${var.environment}-default-sg"
  description = "Security group allowing all inbound/outbound traffic"
  vpc_id = aws_vpc.vpc.id
  depends_on = [
    aws_vpc.vpc]

  ingress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "0"
    to_port = "0"
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
  }

}

/*====
EC2 + KeyPair
======*/

/*resource "aws_key_pair" "coalfire-poc-ec2" {
  key_name   = "coalfire-poc-ec2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPSrgPRWfzFfNRHaOd1KYWjJEmvCPR7JD7j0Sp8OhI+QMMupkUOwJRa6/92eCSCyZ8r2wfI7xHCmJ47Mq70SUYNwjKq3kUcNLtP8sDjm1v3U6k10mFiO6vmeLtm7wzm5Xdvo62iRq4Xw6XfXLkSzN0OYdZEO2dTfBr4McYaKd6XOTr80Cx73WjtURJ64kZdlZ74QYXR4G+t0WQ3jz/vU1LK2EQkP3bwsUMHiT1DrYRf3AN5dYRYyNGf0WUWnrlGxjXj5544D11q45RnN/7FYtwbL/aceeL7HRDdTRXdwmH8cG0fHi2TNCI73fWzE3EhQBCZDnsK9mRnwZKC3gZjIhB coalfire-poc-ec2"
}
*/

resource "aws_instance" "redhat-public" {
  ami = "ami-01e78c5619c5e68b4" /*--Red Hat Enterprise Linux version 8--*/
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public_subnet.0.id
  key_name = "coalfire-poc-ec2"

  root_block_device {
    volume_size = "20"
    volume_type = "standard"
  }
}

resource "aws_instance" "redhat-private" {
  ami = "ami-01e78c5619c5e68b4" /*--Red Hat Enterprise Linux version 8--*/
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private_subnet.0.id
  key_name = "coalfire-poc-ec2"
  user_data = <<-EOF
                  #!/bin/bash
                  sudo su
                  dnf install httpd
                  echo "<p>Apache Server</p>" >> /var/www/html/index.html
                  sudo systemctl enable httpd
                  sudo systemctl start httpd
                  sudo firewall-cmd --zone=public --permanent --add-service=http
                  sudo firewall-cmd --reload
                  EOF

  root_block_device {
    volume_size = "20"
    volume_type = "standard"
  }
}

/*====
ALB + TG
======*/

/* https://github.com/bmadsen85/coalfire-poc/issues/1 */
