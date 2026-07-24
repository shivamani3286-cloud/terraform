resource "aws_vpc" "name" {
    cidr_block = var.cidr_block
    tags = {
        Name = var.tags
    }
}

output "vpc_id" {
  value = aws_vpc.name.id
}
