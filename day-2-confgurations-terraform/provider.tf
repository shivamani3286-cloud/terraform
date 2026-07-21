terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.53.0"
      #version = ">6.53.0"
      #version = >4.0.0, <5.0.0 #example of provider version constraint
    }
  }
}


terraform {
  required_version = ">= 1.5.0" #terraform version constraint
}

provider "aws" {
  region = "us-west-2" #if requires we can change region
}