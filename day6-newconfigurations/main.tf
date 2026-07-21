#creation of vpc
resource "aws_vpc" "shiva_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "shiva_vpc"
  } 
}

#creation of subnet
resource "aws_subnet" "shiva_subnet_public" {
  vpc_id            = aws_vpc.shiva_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "shiva_subnet_public"
  }
}

resource "aws_subnet" "shiva_subnet_private" {
  vpc_id            = aws_vpc.shiva_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "shiva_subnet_private"
  }
}

#creation of internet gateway
resource "aws_internet_gateway" "shiva_igw" {
  vpc_id = aws_vpc.shiva_vpc.id
  tags = {
    Name = "shiva_igw"
  }
}

#creation of route table
resource "aws_route_table" "shiva_route_table" {
  vpc_id = aws_vpc.shiva_vpc.id
  tags = {
    Name = "shiva_route_table"
  }
}

#creation of route
resource "aws_route" "shiva_route" {
  route_table_id         = aws_route_table.shiva_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.shiva_igw.id
}

#association of route table with public subnet
resource "aws_route_table_association" "shiva_route_table_association" {
  subnet_id      = aws_subnet.shiva_subnet_public.id
  route_table_id = aws_route_table.shiva_route_table.id
}

#creation of nat gateway
resource "aws_nat_gateway" "shiva_nat_gateway" {
  allocation_id = aws_eip.shiva_eip.id
  subnet_id     = aws_subnet.shiva_subnet_public.id

  depends_on = [aws_internet_gateway.shiva_igw]

  tags = {
    Name = "shiva_nat_gateway"
  }
}

#creation of route table for private subnet
resource "aws_route_table" "shiva_private_route_table" {
  vpc_id = aws_vpc.shiva_vpc.id
  tags = {
    Name = "shiva_private_route_table"
  }
}

#creation of route for private subnet
resource "aws_route" "shiva_private_route" {
  route_table_id         = aws_route_table.shiva_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.shiva_nat_gateway.id
}

#association of route table with private subnet
resource "aws_route_table_association" "shiva_private_route_table_association" {
  subnet_id      = aws_subnet.shiva_subnet_private.id
  route_table_id = aws_route_table.shiva_private_route_table.id
}

#creation of security group
resource "aws_security_group" "shiva_security_group" {
  name        = "shiva_security_group"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.shiva_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#creation of instance in public subnet
resource "aws_instance" "shiva_instance" {
    ami = "ami-01edba92f9036f76e"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.shiva_subnet_public.id
    vpc_security_group_ids = [aws_security_group.shiva_security_group.id]
    associate_public_ip_address = true
    tags = {
        Name = "shiva-instance-public"
    }
}
resource "aws_instance" "shiva_instanc" {
    ami = "ami-01edba92f9036f76e"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.shiva_subnet_private.id
    vpc_security_group_ids = [aws_security_group.shiva_security_group.id]
    associate_public_ip_address = false
    tags = {
        Name = "shiva-instance-private"
    }

}
resource "aws_eip" "shiva_eip" {
  domain = "vpc"

  tags = {
    Name = "shiva_eip"
  }
}

#creation of db db instance security group
resource "aws_security_group" "shiva_db_security_group" {
  name        = "shiva_db_security_group"
  description = "Allow MySQL traffic"
  vpc_id      = aws_vpc.shiva_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.shiva_subnet_private.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#creation of db instance 
resource "aws_db_instance" "shiva-db" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  db_name                 = "shivadb_22"
  username             = "admin"
  password             = "Shiva1234"
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.shiva_db_security_group.id]

  tags = {
    Name = "shiva-db-instance"
  }
  
}