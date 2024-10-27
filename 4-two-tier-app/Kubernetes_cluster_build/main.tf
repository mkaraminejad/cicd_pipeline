locals {
  ports = [80, 443, 22, 30248, 31000, 6443, 8472, 10250]
}

# AWS Provider:
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-1"
}

# Create a VPC
resource "aws_vpc" "k8s" {
  cidr_block = "10.192.0.0/16"
    
  tags = {
  Name = "K8S Network"
  }
}
# Create Internet GateWay
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.k8s.id

  tags = {
    Name = "To Internet"
  }
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.k8s.id
  cidr_block = "10.192.1.0/24"

  tags = {
    Name = "Public Subnet"
  }
}
#Create Private Subnet
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.k8s.id
  cidr_block = "10.192.2.0/24"

  tags = {
    Name = "Private Subnet"
  }
}
# Create Route Table:
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.k8s.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public Route"
  }
}
# Create Route Table Association:

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.main.id
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "k8s" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.medium"
  #count = 1
  subnet_id   = aws_subnet.public.id
  key_name = "sk8_key"
  private_ip = "10.192.1.10"
  vpc_security_group_ids = [aws_security_group.k8s.id]
  
  connection {
      type        = "ssh"
      host        = self.public_ip
      user        = "ubuntu"
      private_key = file("/home/mmk/test/aws-k8s/key-pair/sk8_key")
      timeout     = "4m"
      
   }
  user_data = <<-EOL
  #!/bin/bash -xe

  sudo apt update
  sudo apt install curl -y
  sudo snap install kubectl --classic
  sudo curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
  sudo mkdir ~/.kube
  sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config 
  sudo chmod 600 ~/.kube/config 
  sudo export KUBECONFIG=~/.kube/config
  EOL

  tags = {
    #Name = "Node00-${count.index+1}"
    Name="Node001"
  }
}

resource "aws_security_group" "k8s" {
  vpc_id = aws_vpc.k8s.id
  egress = [
    {
      cidr_blocks      = [ "0.0.0.0/0", ]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    }
  ]
  # ingress                = [
  #  {
  #    cidr_blocks      = [ "0.0.0.0/0", ]
  #    description      = ""
  #    from_port        = 22
  #    ipv6_cidr_blocks = []
  #    prefix_list_ids  = []
  #    protocol         = "tcp"
  #    security_groups  = []
  #    self             = false
  #    to_port          = 22
  # },
  # {
  #    cidr_blocks      = [ "0.0.0.0/0", ]
  #    description      = ""
  #    from_port        = 30248
  #    ipv6_cidr_blocks = []
  #    prefix_list_ids  = []
  #    protocol         = "tcp"
  #    security_groups  = []
  #    self             = false
  #    to_port          = 30248
  # }
  # ]
    dynamic "ingress" {
    for_each = local.ports
    content {
      description = "description ${ingress.key}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_key_pair" "deployer" {
  key_name   = "sk8_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCr8K2WXIeyGDWrsP0wv04bBv0BqRACpCIUpkFYToK9s6bTKltUDkq1yw3jmNfoEzj/8yElScO4yDW6ftMqICgKRT5fQXr9EYUKUK+VRxlCqYHqKOqgVFh2x+O44CnKD4v/g4mVEhP494CSRNzdnvigczzzeuZN8Ydt6sP9iBCRIvbLVASqIyN7atGHFA8DQKDR1w70/2obsU0ZtsL+DieLnAN5+90GLuCmKPiBteZy4f7k9WDN/UC5n3e1ynElKCvHAhqzdNCY/XHF8ZhMZIXsZsBlW7/3ZoZX40Uf6SvbATRbqzDvb43mOT2XTz+06Kzn3rktiwO+rE343R90JdRJ mmk@mkaramin-JKF66M3"
}

resource "aws_eip" "k8s" {
instance = aws_instance.k8s.id
}

output "Public_IP" {
  value = try(aws_instance.k8s.public_ip, "")
}
output "Private_IP" {
  value = try(aws_instance.k8s.private_ip, "")
}
output "Instance_ARN" {
  value = try(aws_instance.k8s.arn, "")
}
output "Private_DNS" {
  value = try(aws_instance.k8s.private_dns, "")
}


