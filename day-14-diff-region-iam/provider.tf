provider "aws" {
    profile = "test"
    alias = "shivaa"
    region = "us-west-2"
  
}
provider "aws" {
    profile = "dev"
    alias = "shiva"
    region = "us-east-1"
  
}