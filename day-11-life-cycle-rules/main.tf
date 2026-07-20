resource "aws_instance" "name1" {
    ami = "ami-01edba92f9036f76e"
    instance_type = "t3.medium"
    tags = {
      name = "shiva-2"
    }
    lifecycle {
      create_before_destroy = true

    }
    # lifecycle {
    #   ignore_changes = [ tags ]
    # }
    # lifecycle {
    #   prevent_destroy = true
    # }
}

