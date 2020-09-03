provider "aws" {
  region = "ap-south-1"
  profile = "mypratik"
}
resource "aws_db_instance" "mydb" {
  allocated_storage    = 20
  identifier           = "db-instance"
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7.30"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "pratik"
  password             = "root123456"
  iam_database_authentication_enabled = true
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible = true
  tags = {
    Name = "sqldb"
  }
}

resource "null_resource" "minikubeservice"{
 provisioner "local-exec" {
      command = "minikube service list"
   }

depends_on = [
 kubernetes_deployment.wordpress,
 kubernetes_service.wordpresslb,
  aws_db_instance.mydb
 ]
}

resource "null_resource" "minikubestart" {
 provisioner "local-exec" {
      command = "minikube start"
   }
}
provider "kubernetes" {
 config_context_cluster = "minikube"
}
resource "kubernetes_deployment" "wordpress" {
 metadata {
  name = "wp"
 }
spec {
 replicas = 3
 selector {
  match_labels = {
   env = "production"
   region = "IN"
   App = "wordpress"
  }
  match_expressions {
   key = "env"
   operator = "In"
   values = ["production" , "webserver"]
  }
 }
 template {
  metadata {
   labels = {
    env = "production"
    region = "IN"
    App = "wordpress"
   }
  }
  spec {
   container {
    image = "wordpress:4.8-apache"
    name = "wp" 
    }
   }
  }
 }
}
resource "kubernetes_service" "wordpresslb" {
 metadata {
  name = "wplb"
 }
 spec {
  selector = {
   app = "wordpress"
  }
  port {
   protocol = "TCP"
   port = 80
   target_port = 80
  }
  type = "NodePort"
 }
}
