provider "aws" {
    version = "~> 3.0"
    region = var.region
}

//VPC RESOURCES

resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "${var.vpc_prefix}-main"
  }
}

resource "aws_subnet" "web" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_prefix}-web"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.vpc_prefix}-igw"
  }
}

resource "aws_default_route_table" "route_table" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.vpc_prefix}-route_table"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = var.endpoint_service_name
}


//S3 BUCKET AND BUCKET POLICY

resource "aws_s3_bucket" "prateekpratilipi98" {
  bucket = var.bucket_name
  acl    = "private"

  tags = {
    Name        = var.bucket_name
  }
}


resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.prateekpratilipi98.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": ["${aws_iam_role.s3_rw_role.arn}"]
      },
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": ["${aws_s3_bucket.prateekpratilipi98.arn}/*"]
    }
  ]
}
POLICY
}


//IAM ROLE AND POLICY STATEMENT

resource "aws_iam_role" "s3_rw_role" {
  name = "s3_rw_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "S3_rw_policy" {
  name        = "S3_rw_policy"
  description = "Provide S3 read write access"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": ["${aws_s3_bucket.prateekpratilipi98.arn}/*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "S3_EC2_attachment" {
  role       = aws_iam_role.s3_rw_role.name
  policy_arn = aws_iam_policy.S3_rw_policy.arn
}



//SECURITY GROUP CONFIGURATIONS

locals {
  ingress_rules = [{
    port           = 22
    description    = "Port 22"
  },
  {
    port           = 8080
    description    = "Port 8080"
  }
  ]

  egress_rules  = [{
    port           = 3306
    description    = "Port 3306"
  },
  {
    port           = 6379
    description    = "Port 6379"
  }
  ]

}



resource "aws_security_group" "PratilipiSG" {
  name        = "PratilipiSG"
  vpc_id      = aws_vpc.main.id


  dynamic "ingress" {
    for_each = local.ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks  = ["0.0.0.0/0"]
    }

  }

  dynamic "egress" {
    for_each = local.egress_rules

    content {
      description = egress.value.description
      from_port   = egress.value.port
      to_port     = egress.value.port
      protocol    = "tcp"
      cidr_blocks  = ["0.0.0.0/0"]
    }

  }

}

resource "aws_security_group_rule" "endpoint_rule" {
  type              = "egress"
  to_port           = 443
  protocol          = "tcp"
  prefix_list_ids   = [aws_vpc_endpoint.s3.prefix_list_id]
  from_port         = 443
  security_group_id = aws_security_group.PratilipiSG.id
}



//EC2 INSTANCE CONFIGURATIONS

resource "aws_iam_instance_profile" "instance_profile" {
  name  = "instance_profile"
  role = aws_iam_role.s3_rw_role.name
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "ec2_key_pair"
  public_key = file("~/.ssh/id_rsa.pub")
}


resource "aws_instance" "pratilipi" {
  ami                     = var.instance_ami
  instance_type           = var.instance_size
  vpc_security_group_ids  = [aws_security_group.PratilipiSG.id]
  subnet_id               = aws_subnet.web.id
  iam_instance_profile    = aws_iam_instance_profile.instance_profile.name
  key_name                = aws_key_pair.ec2_key_pair.key_name

  tags = {
    "Name" = "${var.vpc_prefix}-instance"
  }
}

