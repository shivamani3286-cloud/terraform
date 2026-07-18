#creation of vpc
resource "aws_vpc" "shiva" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "shiva-terraform-vpc"
  }
}

#creation of public subnet
resource "aws_subnet" "terraform-public-1" {
    vpc_id = aws_vpc.shiva.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
      name = "terraform-public"
    }
    depends_on = [ aws_vpc.shiva ]
}

resource "aws_subnet" "terraform-public-2" {
    vpc_id = aws_vpc.shiva.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
    tags = {
      name = "terraform-public-2"
    }
  depends_on = [ aws_vpc.shiva ]
}

#creation of private subnet
resource "aws_subnet" "terraform-private-1" {
    vpc_id = aws_vpc.shiva.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "us-east-1a"
    tags = {
      name = "terraform-private-1"
    }
  depends_on = [ aws_vpc.shiva ]
}

resource "aws_subnet" "terraform-private-2" {
    vpc_id = aws_vpc.shiva.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "us-east-1b"
    tags = {
      name = "terraform-private-2"
    }
  depends_on = [ aws_vpc.shiva ]
}

#creation internet gateway 
resource "aws_internet_gateway" "terraform-igw" {
    vpc_id = aws_vpc.shiva.id
    tags = {
      name = "terraform-shiva-igw"
    }
}

#creation of route table-1
resource "aws_route_table" "terraform-routetable-1" {
  vpc_id = aws_vpc.shiva.id
  tags = {
    name = "terraform-shiva-routetable"
  }
}

#creation of routes-1
resource "aws_route" "terraform-route-1" {
    route_table_id = aws_route_table.terraform-routetable-1.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-igw.id
}

#creation of route-table-assoction-1
resource "aws_route_table_association" "terraform-route-1" {
    subnet_id = aws_subnet.terraform-public-1.id
    route_table_id = aws_route_table.terraform-routetable-1.id
}

#creation of route table-2
resource "aws_route_table" "terraform-routetable-2" {
  vpc_id = aws_vpc.shiva.id
  tags = {
    name = "terraform-shiva-routetable-2"
  }
}

#creation of routes-2
resource "aws_route" "terraform-route-2" {
    route_table_id = aws_route_table.terraform-routetable-2.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-igw.id
}

#creation of route-table-assoction-2
resource "aws_route_table_association" "terraform-route-2" {
    subnet_id = aws_subnet.terraform-public-2.id
    route_table_id = aws_route_table.terraform-routetable-2.id
}

#creation of elastic ip for nat
resource "aws_eip" "shiva_eip" {
    domain = "vpc"   
    tags = {
        Name = "shiva_eip"
    }
}

#creation of natgateway
resource "aws_nat_gateway" "nat_gatway" {
    vpc_id = aws_vpc.shiva.id
    availability_mode = "regional"
    allocation_id = aws_eip.shiva_eip.id
    tags = {
      name = "terraform-shiva-nat"
    }
}

#creation of route table for nategateway
resource "aws_route_table" "terraform-routetable-private" {
  vpc_id = aws_vpc.shiva.id
  tags = {
    name = "terraform-shiva-routetable-1-private"
  }
}

#creation of routes for natgatway
resource "aws_route" "terraform-route-private" {
    route_table_id = aws_route_table.terraform-routetable-private.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gatway.id
}

#creation of route-table-assoction-for natgateway
resource "aws_route_table_association" "terraform-route-private-1" {
    subnet_id = aws_subnet.terraform-private-1.id
    route_table_id = aws_route_table.terraform-routetable-private.id
}

resource "aws_route_table_association" "terraform-route-private-2" {
    subnet_id = aws_subnet.terraform-private-2.id
    route_table_id = aws_route_table.terraform-routetable-private.id
}

#creation of security group
resource "aws_security_group" "terraform-sg" {
    vpc_id = aws_vpc.shiva.id
    description = "allow"
    name = "terraform-shiva-sg"
    
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress  {
        
            from_port  = 0
            to_port    = 0
            protocol   = "-1"
            cidr_blocks = ["0.0.0.0/0"]
        }
    
}

#creation of public ec2 instance
resource "aws_instance" "public-1" {
  ami = "ami-01edba92f9036f76e"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.terraform-sg.id]
  subnet_id = aws_subnet.terraform-public-1.id
  associate_public_ip_address = "true"
  tags = {
    name = "shiva-terraform-public-ec2-1"
  }
}

resource "aws_instance" "public-2" {
  ami = "ami-01edba92f9036f76e"
  instance_type = "t3.micro"
  vpc_security_group_ids = [aws_security_group.terraform-sg.id]
  subnet_id = aws_subnet.terraform-public-2.id
  associate_public_ip_address = "true"
  tags = {
    name = "shiva-terraform-public-ec2-2"
  }
}

#creation of private ecc2 instance
resource "aws_instance" "private-1" {
    ami = "ami-01edba92f9036f76e"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.terraform-sg.id]
    associate_public_ip_address = "false"
    subnet_id = aws_subnet.terraform-private-1.id
    tags = {
        name = "shiva-teraaform-private-ec2-1"
    }
}

resource "aws_instance" "private-2" {
    ami = "ami-01edba92f9036f76e"
    instance_type = "t3.micro"
    vpc_security_group_ids = [aws_security_group.terraform-sg.id]
    associate_public_ip_address = "false"
    subnet_id = aws_subnet.terraform-private-2.id
    tags = {
        name = "shiva-teraaform-private-ec2-2"
    }
}

#creation of target-group
resource "aws_lb_target_group" "ta-1" {
    target_type = "instance"
    name = "tg-1-terraform-shiva"
    protocol = "HTTP"
    port = 80
    vpc_id = aws_vpc.shiva.id
    protocol_version = "HTTP1"
    health_check {
      enabled = true
      path = "/"
      protocol = "HTTP"
      matcher = "200"
    }
  tags = {
    name = "terraform-target-group-shiva"
  }
}

#creation of laod balancer
resource "aws_lb" "lb" {
    load_balancer_type = "application"
    name = "shiva-terraform-lb"
    internal = false
    security_groups = [aws_security_group.terraform-sg.id]
    subnets = [
        aws_subnet.terraform-public-1.id,
        aws_subnet.terraform-public-2.id
    ]
    enable_deletion_protection = false

}

#creation of the lb lisner
resource "aws_lb_listener" "lb" {
    load_balancer_arn = aws_lb.lb.arn
    port = "80"
    protocol = "HTTP"

    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.ta-1.arn
    }

}

#connection of  of lb to ec2
resource "aws_lb_target_group_attachment" "app_instance_1" {
  target_group_arn = aws_lb_target_group.ta-1.arn
  target_id        = aws_instance.public-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app_instance_2" {
  target_group_arn = aws_lb_target_group.ta-1.arn
  target_id        = aws_instance.public-2.id
  port             = 80
}

#creation of iam role, group, and policies using Terraform and validate access permissions
resource "aws_iam_role" "shiva-1" {
   description = "neww"
   name        = "shiva-1"
   assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
         "Effect": "Allow",
         "Principal": {
            "Service": "ec2.amazonaws.com"
         },
         "Action": "sts:AssumeRole"
      }
   ]
}
EOF
}

#creation of iam_group
resource "aws_iam_group" "shiva-iam-group" {
    name = "shiva-iam-group"
    path = "/"
}

#attachment of iam-user to group
resource "aws_iam_user_group_membership" "shiva" {
   user = aws_iam_user.shiva.name

   groups = [
      aws_iam_group.shiva-iam-group.name
   ]
}

# IAM user for membership
resource "aws_iam_user" "shiva" {
   name = "shiva-terraform"
   path = "/"
}

module "rds" {
  source = "../day-10-module-rds"

  db_identifier      = "shiva-rds"
  engine             = "mysql"
  engine_version     = "8.0"
  instance_class     = "db.t3.micro"
  allocated_storage  = 20

  username = "admin"
  password = "Password123"

  subnet_group_name = "shiva-rds-subnet-group"

  subnet_ids = [
    aws_subnet.terraform-public-1.id,
    aws_subnet.terraform-public-2.id
  ]

  security_group_ids = [
    aws_security_group.terraform-sg.id
  ]

  publicly_accessible = true
}

