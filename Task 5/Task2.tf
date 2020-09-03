provider "aws" {
  region     = "ap-south-1"
  profile    = "mypratik"
}

#Creating Key

resource "tls_private_key" "key_form" {
  algorithm = "RSA"
}

resource "aws_key_pair" "task2_key" {
  key_name   = "mykey1112"
  public_key = tls_private_key.key_form.public_key_openssh
}


resource "aws_vpc" "pratik_vpc" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy="default"
  enable_dns_hostnames = true
  tags = {
    Name = "pratik_vpc"
  }
}

resource "aws_subnet" "pratik_subnet" {
  vpc_id            = aws_vpc.pratik_vpc.id
  availability_zone = "ap-south-1a"
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "pratik_subnet"
  }
}

resource "aws_internet_gateway" "mygateway" {
  vpc_id = aws_vpc.pratik_vpc.id
  tags = {
    Name = "mygateway"
  }
}
resource "aws_route_table" "myroutetable" {
  vpc_id = aws_vpc.pratik_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygateway.id
  }
  tags = {
    Name = "myroutetable"
  }
}
resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.pratik_subnet.id
  route_table_id = aws_route_table.myroutetable.id
}

#Creating Security group
resource "aws_security_group" "mysg" {
  name        = "mysg"
  description = "Allow HTTP,ssh for inbound traffic"
  vpc_id      = aws_vpc.pratik_vpc.id

  ingress {
    description = "Http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysecuritygroup"
  }
}

#Creating EFS
resource "aws_efs_file_system" "myefs" {
  creation_token = "my-efs"
  performance_mode="generalPurpose"
  tags = {
    Name = "myefs"
  }
}

resource "aws_efs_file_system_policy" "policy" {
  file_system_id = aws_efs_file_system.myefs.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Id": "efs-policy-wizard-c45881c9-af16-441d-aa48-0fbd68ffaf79",
    "Statement": [
        {
            "Sid": "efs-statement-20e4223c-ca0e-412d-8490-3c3980f60788",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Resource": "${aws_efs_file_system.myefs.arn}",
            "Action": [
                "elasticfilesystem:ClientMount",
                "elasticfilesystem:ClientWrite",
                "elasticfilesystem:ClientRootAccess"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "true"
                }
            }
        }
    ]
}
POLICY
}

#Mount EFS to EC2 instance
resource "aws_efs_mount_target" "mymount" {
  file_system_id = aws_efs_file_system.myefs.id
  subnet_id      = aws_subnet.pratik_subnet.id
  security_groups = [ "${aws_security_group.mysg.id}" ]
}

#Creating ec2 instance

resource "aws_instance" "myin" {
  ami           = "ami-00b494a3f139ba61f"
  instance_type = "t2.micro"
  key_name      = "mykey1112"
  availability_zone = "ap-south-1a"
  subnet_id     = aws_subnet.pratik_subnet.id
  security_groups = [ "${aws_security_group.mysg.id}" ]
  tags = {
    Name = "myterraOS"
  }
}
resource "null_resource" "null_vol_attach"  {
  depends_on = [
    aws_efs_mount_target.mymount,
  ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.key_form.private_key_pem
    host     = aws_instance.myin.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "sudo yum install -y httpd git php amazon-efs-utils nfs-utils",
      "sudo yum install git",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd",
      "sudo chmod ugo+rw /etc/fstab",
      "sudo echo '${aws_efs_file_system.myefs.id}:/ /var/www/html efs tls,_netdev' >> /etc/fstab",
      "sudo mount -a -t efs,nfs4 defaults",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/Pratikkohad1999/multicloud.git /var/www/html/"
    ]
  }
}

#Creating S3 Bucket
resource "aws_s3_bucket" "mybucket" {
  bucket = "pratik1234"
  acl    = "public-read"
  force_destroy  = true
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "POST"]
    allowed_origins = ["https://pratik1234"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
  
depends_on = [
   null_resource.null_vol_attach,
  ]
}

#putting object inside the s3 bucket
resource "aws_s3_bucket_object" "myobj" {
  key = "1234.jpg"
  bucket = aws_s3_bucket.mybucket.id
  source = "C:/Users/Asus/Downloads/1234.jpg"
  acl="public-read"
}


# Create Cloudfront distribution

locals {
   s3_origin_id=aws_s3_bucket.mybucket.bucket
   image_url="$(aws_cloudfront_distribution.mycdistribution.domain_name)/$(aws_s3_bucket_object.image-pull.key)"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity"{
    comment="Sync Cloudfront to s3"
}
 
resource "aws_cloudfront_distribution" "mycdistribution" {
   origin {
         domain_name=aws_s3_bucket.mybucket.bucket_regional_domain_name
          origin_id=local.s3_origin_id

   s3_origin_config {
       origin_access_identity=aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
}

 enabled=true
 is_ipv6_enabled=true
 default_root_object="index.php"

 custom_error_response {
   error_caching_min_ttl=3000
   error_code=404
   response_code=200
   response_page_path="/1234.jpg"
}

default_cache_behavior {
   allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
   cached_methods = ["GET", "HEAD"]
   target_origin_id = local.s3_origin_id

   forwarded_values {
      query_string=false
   cookies {
     forward= "none"
  }
}

viewer_protocol_policy= "allow-all"
   min_ttl= 0
   default_ttl= 3600
   max_ttl= 86400
}

 restrictions {
   geo_restriction {
      restriction_type="none"
   }
}

viewer_certificate {
   cloudfront_default_certificate=true
}

tags = {
  Name="mycdistribution"
  }

connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key =  tls_private_key.key_form.private_key_pem
    host     = aws_instance.myin.public_ip
  }


  provisioner "remote-exec" {
    inline = [
        "sudo su << EOF",
        "sudo chmod ugo+rw /var/www/html/",
        "sudo echo \"<img src='http://${aws_cloudfront_distribution.mycdistribution.domain_name}/$(aws_s3_bucket_object.image-pull.key)'>\" >> /var/www/html/index.php",
        "EOF"
    ]
  }
}


output "cloudfront_ip_addr" {
  value = aws_cloudfront_distribution.mycdistribution.domain_name
}

resource "null_resource" "key_pair"  {
	provisioner "local-exec" {
	    command = "echo  '${tls_private_key.key_form.private_key_pem}' > key.pem"
  	}
}