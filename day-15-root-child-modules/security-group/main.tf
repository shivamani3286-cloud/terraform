resource "aws_security_group" "shiva_security_group" {
    name = var.sg_name
    vpc_id = var.vpc_id
    description = var.sg_description

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = var.sg_cidr_blocks
    }

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        cidr_blocks = var.sg_cidr_blocks
    }
    egress  {
        
            from_port  = 0
            to_port    = 0
            protocol   = "-1"
            cidr_blocks = var.sg_cidr_blocks
        }
    
}

output "security_group_id" {
  value = aws_security_group.shiva_security_group.id
}
