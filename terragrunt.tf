# Infrastructure Modules

infrastrcture-modules/vpc/

resource "aws_vpc" "demo" {
  cidr_block = var.vpc_cidr
  tags = {
    env = var.env
  }
}

# Subnets for dependency
resource "aws_subnet" "demo" {
  vpc_id = aws_vpc.demo.id
  cidr_block = var.subnet_cidr
  tags = {
    env = var.env
  }
}

# Output this vpc id and subnet id for ec2 creation
output "vpc_id" {
  value = aws_vpc.demo.id
}

output "subnet_id" {
  value = aws_subnet.demo.id
}


# Go inside infra-live/

create dev and prod folders

create root.hcl in infra-live

# DRY Concept - Don't repeat yourself

