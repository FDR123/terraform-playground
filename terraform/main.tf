locals {
  common_tags = {
    Terraform   = "true"
    Environment = "dev"
  }
  region = "eu-central-1"
}


provider "aws" {
  region = local.region
}


data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "main"
    },
  )
}

resource "aws_subnet" "private" {
  count = 2

  cidr_block = "10.0.${count.index + 1}.0/24"
  vpc_id     = aws_vpc.main.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.common_tags,
    {
      Name = "private-${count.index + 1}"
    },
  )
}

resource "aws_security_group" "lambda" {
  name_prefix = "lambda"
  description = "Allow inbound traffic to Lambda functions"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  tags = local.common_tags
}

resource "aws_db_subnet_group" "rds" {
  name       = "main"
  subnet_ids = aws_subnet.private.*.id

  tags = local.common_tags
}

resource "aws_security_group" "rds" {
  name_prefix = "rds"
  description = "Allow inbound traffic to RDS instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda.id]
  }

  tags = local.common_tags
}

resource "aws_db_instance" "postgres" {
  identifier             = "mypostgresdb"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "15.2"
  instance_class         = "db.t3.micro"
  username               = var.postgres_username
  password               = var.postgres_password
  db_subnet_group_name   = aws_db_subnet_group.rds.id
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true

  tags = local.common_tags
}


module "lambda_module" {
  source       = "./modules/lambda"
  common_tags = local.common_tags
  region = local.region
  subnet_ids      = aws_subnet.private.*.id
  security_group_id = aws_security_group.lambda.id
}
