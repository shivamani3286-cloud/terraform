data "aws_instance" "name" {
    filter {
      name = "tag:Name"
      values = ["shiva"]
    }
  
}