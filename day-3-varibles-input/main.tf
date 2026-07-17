resource "aws_instance" "name" {
    ami = var.ami_id
    instance_type = var.instance_type
    subnet_id = aws_subnet.name.id
    vpc_security_group_ids = [aws_security_group.my_security_group.id]
    tags = {
        Name = var.tags
    }
  
}
resource "aws_vpc" "name" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "dev"
    }
  
}

resource "aws_subnet" "name" {
    vpc_id                  = aws_vpc.name.id
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "us-east-1a"  # change to your region's AZ
    map_public_ip_on_launch = true
    tags = {
        Name = "dev-subnet"
    }
}

resource "aws_security_group" "my_security_group" {
    name        = "my-security-group"
    description = "Allow SSH and HTTP traffic"
    vpc_id      = aws_vpc.name.id

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