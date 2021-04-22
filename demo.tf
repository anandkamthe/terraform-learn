provider "aws" {
    region= "ca-central-1"
}

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_IP{}
variable instance_type{}

resource "aws_vpc" "my_vpc" {
   cidr_block = var.vpc_cidr_block
   tags = { Name: "${var.env_prefix}-vpc" }
}

resource "aws_subnet" "my_subnet-1" {
   vpc_id = aws_vpc.my_vpc.id
   cidr_block = var.subnet_cidr_block
   availability_zone = var.avail_zone
   tags= { 
       Name= "${var.env_prefix}-subnet-1"
   }
}
resource "aws_internet_gateway" "my_igw" {
   vpc_id = aws_vpc.my_vpc.id
   tags= {
       Name= "${var.env_prefix}-igw"
   }
}
resource "aws_route_table" "my_route_table" {
   vpc_id= aws_vpc.my_vpc.id
   route {
       cidr_block= "0.0.0.0/0"
       gateway_id= aws_internet_gateway.my_igw.id
   }
   tags= {
       Name= "${var.env_prefix}-rtb"
   }
}

resource "aws_route_table_association" "my_rtbsa" {
    subnet_id = aws_subnet.my_subnet-1.id
    route_table_id = aws_route_table.my_route_table.id  
}

resource "aws_security_group" "my_sg" {
   name = "my-sg"
   vpc_id = aws_vpc.my_vpc.id
   ingress {
       from_port = 22
       to_port = 22
       protocol = "tcp"
       cidr_blocks= [var.my_IP]
   }
   ingress {
       from_port = 8080
       to_port = 8080
       protocol = "tcp"
       cidr_blocks= ["0.0.0.0/0"]
   }
   egress {
       from_port = 0
       to_port = 0
       protocol = "-1"
       cidr_blocks= ["0.0.0.0/0"]
       prefix_list_ids = []
   }
   tags= {
       Name= "${var.env_prefix}-sg"
   }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values= ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
}
resource "aws_instance" "my_server" {
   ami = data.aws_ami.latest-amazon-linux-image.id 
   instance_type = var.instance_type
   subnet_id = aws_subnet.my_subnet-1.id
   vpc_security_group_ids = [ aws_security_group.my_sg.id ]
   availability_zone = var.avail_zone
   associate_public_ip_address = true
   key_name = "canada"
   user_data = <<EOF
                   #!/bin/bash
                   sudo yum update -y && sudo yum install -y docker
                   sudo systemctl start docker
                   sudo usermod -aG docker ec2-user
                   docker run -p 8080:80 nginx 

                EOF

   tags= {
       Name= "${var.env_prefix}-instance"
   }
}