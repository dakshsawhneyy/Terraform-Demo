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

# Generate provider inside root.hcl
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "ap-south-1"
}
EOF
}


# Remote Backend
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "my-unique-terraform-state-bucket"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
  }
}


# creating vpc inside dev

create folder vpc inside dev
create file terragrunt.hcl


# use root parent folder at top
include "root" {
  path = find_in_parent_folders("root.hcl")
}

run terragrunt init
