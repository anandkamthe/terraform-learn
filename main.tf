provider "aws" {
    region = "ca-central-1"
    
}

variable "subnet-cidr-block"{
    description= "subnet cidr block"
}
variable "vpc-env"{
    description= "environment of vpc"
}
resource "aws_vpc" "development-vpc"{
    cidr_block="10.0.0.0/16"
    tags = {    
        Name = var.vpc-env
    }
}

resource "aws_subnet""development-subnet"{
    vpc_id=aws_vpc.development-vpc.id
    cidr_block=var.subnet-cidr-block
    availability_zone="ca-central-1a"
}

data "aws_vpc""existing_vpc"{
    default= true
}

resource "aws_subnet""development_subnet-1"{
    vpc_id = data.aws_vpc.existing_vpc.id
    cidr_block= "172.31.48.0/20"
    availability_zone= "ca-central-1b"

}

output "dev_vpc_id" {
    value = aws_vpc.development-vpc.id
}
output "dev_subnet_id" {
    value = aws_subnet.development-subnet.id
}
output "dev_default_subnet_id" {
    value = aws_subnet.development_subnet-1.id
}