# Infrastructure Modules

modules/vpc/

# main.tf
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

# Output this vpc id and subnet id for ec2 module creation
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

create folder vpc and go inside it 
create file terragrunt.hcl

# Call module directly inside the file

terraform {
  # Source of module
  source = "../../../modules"
}
inputs {
  # start providing inputs 
}

# use root parent folder at top of terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terragrunt init
terragrunt plan
terragrunt apply


# Now go to prod folder

create file terragrunt.hcl

# Call module directly inside the file

terraform {
  # Source of module
  source = "../../modules/vpc"
}
inputs {
  # start providing inputs 
}

# use root parent folder at top of terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terragrunt init
terragrunt plan
terragrunt apply



# introducing dependencies

create new module ec2

main.tf 

resource "aws_instance" "demo" {
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  ami = var.ami
}

go inside dev folder and create ec2 folder and initialize terragrunt.hcl

terraform {
  # Source of module
  source = "../../../modules/ec2"
}
inputs {
  # start providing inputs 
  subnet_id =    (dependency)
}

depedency "vpc" {
  config_path = "../../../modules/vpc"    # vpc module location
}
