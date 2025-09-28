provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "app_repo" {
  name                 = "clo835-assignment1-app"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "db_repo" {
  name                 = "clo835-assignment1-db"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "clo835-key"
  public_key = file("~/.ssh/clo835-key.pub")
}

resource "aws_security_group" "ec2_sg" {
  name        = "clo835-assignment-sg"
  description = "Allow SSH and application web traffic"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8081
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = "LabInstanceProfile"
  user_data = <<-EOT
                #!/bin/bash
                yum update -y
                amazon-linux-extras install docker -y
                service docker start
                usermod -a -G docker ec2-user
                chkconfig docker on
                EOT
  tags = {
    Name = "CLO835 Assignment 1 Server"
  }
}

output "instance_public_ip" {
  value       = aws_instance.app_server.public_ip
  description = "The public IP address of the EC2 instance."
}
