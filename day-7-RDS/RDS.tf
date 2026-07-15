#create a VPC
resource "aws_vpc" "shiva-vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        Name = "shiva-vpc"
    }
}

#create a public subnet-1
resource "aws_subnet" "shiva_subnet_public" {
    vpc_id = aws_vpc.shiva-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "shiva_subnet_public"
    }
}


#creation of public subnet-2
    resource "aws_subnet" "shiva_subnet_public-2" {
        vpc_id = aws_vpc.shiva-vpc.id
        cidr_block = "10.0.2.0/24"
        availability_zone = "us-east-1b"
        tags = {
            Name = "shiva_subnet_public-2"
        }
    }


#creation of private subnet-1
resource "aws_subnet" "shiva_subnet_private-1" {
    vpc_id = aws_vpc.shiva-vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "us-east-1c"
    tags = {
        Name = "shiva_subnet_private-1"
    }
}

#creation of private subnet-2
resource "aws_subnet" "shiva_subnet_private-2" {
    vpc_id = aws_vpc.shiva-vpc.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "us-east-1d"
    tags = {
        Name = "shiva_subnet_private-2"
    }
}

#creation of intenet gateway 
resource "aws_internet_gateway" "shiva_igw" {
    vpc_id = aws_vpc.shiva-vpc.id
    tags = {
        Name = "shiva_igw"

    }
}

#CREATIONS OF ROUTE TABLE
resource "aws_route_table" "shiva_route_table" {
    vpc_id =aws_vpc.shiva-vpc.id
    tags = {
        Name = "shiva_route_table"
    }
}

#creation of routings
resource "aws_route" "shiva_route" {
    route_table_id = aws_route_table.shiva_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.shiva_igw.id
    
}

#creation of route table association
resource "aws_route_table_association" "shiva_route_table_association" {
    subnet_id = aws_subnet.shiva_subnet_public.id
    route_table_id =aws_route_table.shiva_route_table.id

}

#creation of route table for public subnet-2
resource "aws_route_table" "shiva_route_table_2" {
    vpc_id = aws_vpc.shiva-vpc.id
    tags = {
        Name = "shiva_route_table_2"
    }
    }

#creation of routing for public subnet-2
resource "aws_route" "shiva_route_2" {
    route_table_id = aws_route_table.shiva_route_table_2.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.shiva_igw.id
}

#creation of route table association for public subnet-2
resource "aws_route_table_association" "shiva_route_table_association_2" {
    subnet_id = aws_subnet.shiva_subnet_public-2.id
    route_table_id = aws_route_table.shiva_route_table_2.id
}

#creation of elastic ip for nat agteway
resource "aws_eip" "shiva_eip" {
    domain = "vpc"   
    tags = {
        Name = "shiva_eip"
    }
}

#creation of nat gateway
resource "aws_nat_gateway" "shiva_nat_gateway" {
    subnet_id     = aws_subnet.shiva_subnet_public.id
    allocation_id = aws_eip.shiva_eip.allocation_id
    tags = {
        Name = "shiva_nat_gateway"
    }
}

#creation of route table for private subnets
resource "aws_route_table" "shiva_private_route_table" {
    vpc_id = aws_vpc.shiva-vpc.id
    tags = {
        Name = "shiva_private_route_table"
    }
}

#creation of routing for private subnets
resource "aws_route" "shiva_private_route" {
    route_table_id =aws_route_table.shiva_private_route_table.id
    destination_cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.shiva_nat_gateway.id
}

#creation of route table association for private subnets
resource "aws_route_table_association" "shiva_private_route" {
    subnet_id = aws_subnet.shiva_subnet_private-1.id
    route_table_id = aws_route_table.shiva_private_route_table.id
}

resource "aws_route_table_association" "shiva_private_route_2" {
    subnet_id = aws_subnet.shiva_subnet_private-2.id
    route_table_id = aws_route_table.shiva_private_route_table.id
}

#creation of security group 
resource "aws_security_group" "shiva_security_group" {
    name = "shiva_sg"
    vpc_id = aws_vpc.shiva-vpc.id
    description = "Security group for shiva instances"

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

#creation of instance in public subnet-1

resource "aws_instance" "shiva_instance_public" {
    ami                          = "ami-01edba92f9036f76e"
    instance_type                = "t3.micro"
    subnet_id                    = aws_subnet.shiva_subnet_public.id
    vpc_security_group_ids       = [aws_security_group.shiva_security_group.id]
    associate_public_ip_address  = true
    tags = {
        Name = "terraform-shiva-instance-public"
    }
}

#creation of instance in private subnet-1
resource "aws_instance" "shiva_instance_private" {
    ami                          = "ami-01edba92f9036f76e"
    instance_type                = "t3.micro"
    subnet_id                    = aws_subnet.shiva_subnet_private-1.id
    vpc_security_group_ids       = [aws_security_group.shiva_security_group.id]
    tags = {
        Name = "terraform-shiva-instance-private"
    }
}

#creation of db subnet groups
resource "aws_db_subnet_group" "shiva_db" {
    name = "shiva_db"
  subnet_ids = [
    aws_subnet.shiva_subnet_public.id,
    aws_subnet.shiva_subnet_public-2.id
  ]
 tags = {
   Name = "shiva_db"
 }
}

#creation of database
resource "aws_db_instance" "shiva-db" {
    identifier = "shiva-db"
    engine = "mysql"
    engine_version         = "8.0"
    instance_class         = "db.t3.micro"
    allocated_storage      = 20
    username               = "admin"
    password               = "Password123"
    db_subnet_group_name = aws_db_subnet_group.shiva_db.name
    vpc_security_group_ids = [aws_security_group.shiva_security_group.id]
    publicly_accessible    = true
    skip_final_snapshot    = true
    backup_retention_period = 1
}

#creation of read replica
resource "aws_db_instance" "read_replica" {
    identifier           = "shiva-readreplica"
    replicate_source_db  = aws_db_instance.shiva-db.identifier
    instance_class        = "db.t3.micro"
    publicly_accessible   = true
    skip_final_snapshot   = true
    tags = {
        Name = "read_replica"
    }
}

#creation of redis cache
resource "aws_elasticache_cluster" "redis_cache" {
    cluster_id = "shiva-redis"
    engine = "redis"
    node_type = "cache.t3.micro"
    num_cache_nodes = 1
}

