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


