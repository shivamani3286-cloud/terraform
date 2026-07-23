resource "aws_s3_bucket" "name" {
    bucket = "bhjdshjdsghcd"
    provider = aws.shiva
}

resource "aws_vpc" "name" {
    cidr_block = "10.0.0.0/16"
    provider = aws.shivaa
    tags = {
      Name = "shivaaa"
    }
     
}