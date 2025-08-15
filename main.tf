provider "aws" {
  region = "us-east-1"
}

data "aws_vpc" "default" {
  default = true
}



resource "aws_security_group" "allow_all" {
  name        = "allow_all_techtest"
  description = "Allow all required ports"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Mongo"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "API"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Frontend"
    from_port   = 5173
    to_port     = 5173
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Mongo Express"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_instance" "techtest_instance" {
  ami                         = "ami-053b0d53c279acc90" # Ubuntu 22.04 LTS us-east-1
  instance_type               = "t3.medium"
  key_name                    = "terraform-key"
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  associate_public_ip_address = true
  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io docker-compose git
              systemctl start docker
              systemctl enable docker
              git clone https://github.com/brian980414/terraform_deploy.git /opt/app
              cd /opt/app
              docker-compose up -d
              EOF

  tags = {
    Name = "techtest-ec2"
  }
}

