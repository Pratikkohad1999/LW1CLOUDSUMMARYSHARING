provider "aws" {
  region   = "ap-south-1"
  profile  = "Pratik"
}
resource "aws_vpc" "myvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames  = true

  tags = {
    Name = "pratik_vpc"
  }
}
resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "pratikpublicsubnet"
  }
}
resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "pratikprivatesubnet"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.myvpc.id}"

  tags = {
    Name = "pratikIG"
  }
}
resource "aws_route_table" "forig" {
  vpc_id = "${aws_vpc.myvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = {
    Name = "IGroutetable"
  }
}
resource "aws_route_table_association" "asstopublic" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.forig.id
}
resource "aws_security_group" "webserver" {
  name        = "for_wordpress"
  description = "Allow http,ssh"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mywebserver_sg"
  }
}
resource "aws_security_group" "database" {
  name        = "for_MYSQL"
  description = "Allow ssh and MYSQL"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "MYSQL"
    security_groups = [aws_security_group.webserver.id]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mydatabase_sg"
  }
}
resource "aws_instance" "wordpress" {
  ami           = "ami-00b494a3f139ba61f"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.webserver.id]
  key_name = "mykey111"
  

  tags = {
    Name = "wordpress"
  }

}
resource "aws_instance" "mysql" {
  ami           = "ami-0019ac6129392a0f2"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.database.id]
  key_name = "mykey111"
  

 tags = {
    Name = "mysql"
  }

}