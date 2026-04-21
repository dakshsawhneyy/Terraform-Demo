VPC Module
infra.vpc/
 ├── vpc.tf
 ├── subnet.tf
 ├── igw.tf
 ├── route_table.tf
 ├── variables.tf
 ├── outputs.tf


resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  tags = {
    Name        = "${var.env}-vpc"
    Environment = var.env
  }
}

resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env}-public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  count = length(aws_subnet.public_subnets)

  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

variable "env" {}
variable "vpc_cidr" {}
variable "public_subnet_cidrs" {
  type = list(string)
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}


# Call VPC Module in main.tf

module "dev-vpc" {
  source = "./infra.vpc"

  env                  = "dev"
  vpc_cidr             = "10.0.0.0/16"
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
}

module "prd-vpc" {
  source = "./infra.vpc"

  env                  = "prd"
  vpc_cidr             = "10.1.0.0/16"
  public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
}


####################################
############ Creating Custom Module

# Create folder (infra.app)

# Create 3 templates inside folder
S3.tf
dynamodb.tf
ec2.tf

# S3.tf
resource "aws_s3_bucket" "my_app_bucket" {
  bucket = "${var.env}-${var.bucket_name}"

  tags = {
    Name = "${var.env}-${var.bucket_name}"
    Environment = ${var.env}
  }
}

### Add variables

# EC2.tf

resource "aws_key_pair" "deployer" {
  key_name   = "${var.my_env}-terra-automate-key"
  public_key = file("terra-key.pub")
}

# generate key
ssh-keygen -t rsa -b 4096 -f terra-key

resource "aws_default_vpc" "default" {
}

resource "aws_security_group" "allow_user_to_connect" {
  name        = "${var.my_env}-allow-TLS"
  description = "Allow user to connect"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "port 22 allow"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "allow all outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "port 80 allow"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "port 443 allow"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.my_env}-mysecurity"
  }
}

resource "aws_instance" "my_app_server" {
  count                  = var.instance_count
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.allow_user_to_connect.id]

  root_block_device {
    volume_size = var.env == "prd" ? 20 : 10
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.env}-tws-demo-app-server"
    Environment = var.env
  }
}


# DynamoDB table

resource "aws_dynamodb_table" "my_app_table" {
    name = "${var.my_env}-tws-demo-app-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "userID"
    attribute {
        name = "userID"
        type = "S"
    }
    tags = {
        Name = "${var.my_env}-tws-demo-app-table"
        Environment = var.env
    }
}



# Come Out of folder

# Create providers.tf
provider "aws" {
  region = "ap-south-1"
}

# Go to main.tf

module "dev-app" {
  source        = "./my_app_infra_module"
  my_env        = "dev"
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu.id
}

module "prd-app" {
  source        = "./my_app_infra_module"
  my_env        = "dev"
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu.id
}

module "stg-app" {
  source        = "./my_app_infra_module"
  my_env        = "dev"
  instance_type = "t2.micro"
  ami           = data.aws_ami.ubuntu.id
}
