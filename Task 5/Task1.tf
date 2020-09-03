provider "aws" {
  region     = "ap-south-1"
  access_key = "my-access-key"
  secret_key = "my-secret-key"
}

resource "aws_key_pair" "mykey11" {
	key_name = "mykey11"
	public_key = "my-public-key"

resource "aws_security_group" "terra1" {
  name        = "terra1"
  description = "Allow TCP inbound traffic"
  vpc_id      = "vpc-26e3ff4e"

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
	from_port = 0
 	to_port = 0
	protocol = "-1"
	cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "mypratik"
  }
}


resource "aws_instance" "mypratik" {
	ami = "ami-0447a12f28fddb066"
	instance_type = "t2.micro"
	key_name = "mykey11"
	security_groups = ["terra1"]
	user_data = <<-EOF
		#!/bin/bash
		sudo yum install httpd -y
		sudo systemctl start httpd
		sudo systemctl enable httpd
		sudo yum install git -y
		mkfs.ext4 /dev/df1
		mount /dev/df1 /var/www/html
		cd /var/www/html
	git  clone https://github.com/Pratikkohad1999/multicloud.git
	EOF
	tags = { 
		  Name = "mypratik"
        }
}

resource "aws_ebs_volume" "my lw pendrive" {
  availability_zone = aws_instance.mypratik.availability_zone
  size              = 1

  tags = {
    Name = "my lw pendrive"
  }
}


resource "aws_volume_attachment" "EBSattach" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.my lw pendrive.id
  instance_id = aws_instance.mypratik.id
}


resource "aws_s3_bucket" "terra-s1" {
  bucket = "terra-s1"
}

resource "aws_s3_bucket_public_access_block" "access" {
  bucket = "${aws_s3_bucket.terra-s1.id}"

  block_public_acls   = true
  block_public_policy = true
}