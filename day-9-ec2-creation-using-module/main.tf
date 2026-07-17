module "dev" {
    source ="../day-9-module"
    ami_id = "ami-01edba92f9036f76e"
    instance_type = "t3.micro"
    tags = "dev-instance"
  
}