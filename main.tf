provider "aws" {
  region = var.region
}

# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 6.0"
#     }
#   }
#   cloud {
#     organization = "KubOrg1"

#     workspaces {
#       name = "Webservers"
#     }
#   }
# }

terraform {
  required_version = "~> 1.16"

  backend "s3" {
    bucket       = "tf-state-bucket-892a1aaa"
    key          = "web-usw2/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

resource "tls_private_key" "key_pair2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the Key Pair
resource "aws_key_pair" "key_pair2" {
  key_name   = "my-key-pair2"
  public_key = tls_private_key.key_pair2.public_key_openssh
}

# Define a security group for the EC2 instances
resource "aws_security_group" "web_sg" {
  name_prefix = "web-sg-"
  description = "Allow HTTP and SSH access"
  vpc_id      = aws_default_vpc.default.id # Use the default VPC ID

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSH from anywhere (for demonstration, restrict in production)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }

  tags = {
    Name = "web-sg"
  }
}

resource "aws_default_vpc" "default" {
  force_destroy = true
  tags = {
    Name = "default-vpc"
  }
}

# Data source to get an Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical's AWS account ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create the first EC2 instance
resource "aws_instance" "web_instance_1" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro" # Or your desired instance type
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true # Assign a public IP for access
  key_name                    = aws_key_pair.key_pair2.key_name
  user_data                   = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Web Instance 1!</h1>" > /var/www/html/index.html
              mkdir /var/www/html/admin
              echo "<h1>Hello from Web Instance 1!......admin</h1>" > /var/www/html/admin/index.html
              EOF

  tags = {
    Name = "WebInstance-1"
  }
}

# Create the second EC2 instance
resource "aws_instance" "web_instance_2" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro" # Or your desired instance type
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true # Assign a public IP for access
  key_name                    = aws_key_pair.key_pair2.key_name
  user_data                   = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Web Instance 2!</h1>" > /var/www/html/index.html
              mkdir /var/www/html/admin
              echo "<h1>Hello from Web Instance 2!......admin</h1>" > /var/www/html/admin/index.html
              EOF

  tags = {
    Name = "WebInstance-2"
  }
}

# Create the third EC2 instance
resource "aws_instance" "web_instance_3" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3.micro" # Or your desired instance type
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true # Assign a public IP for access
  key_name                    = aws_key_pair.key_pair2.key_name
  user_data                   = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Web Instance 3!</h1>" > /var/www/html/index.html
              mkdir /var/www/html/admin
              echo "<h1>Hello from Web Instance 3!......admin</h1>" > /var/www/html/admin/index.html
              EOF

  tags = {
    Name = "WebInstance-3"
  }
}

# Output the public IPs of the instances
output "web_instance_1_public_dns" {
  description = "The public IP address of Web Instance 1"
  value       = aws_instance.web_instance_1.public_dns
}

output "web_instance_2_public_dns" {
  description = "The public IP address of Web Instance 2"
  value       = aws_instance.web_instance_2.public_dns
}

output "web_instance_3_public_dns" {
  description = "The public IP address of Web Instance 3"
  value       = aws_instance.web_instance_3.public_dns
}
