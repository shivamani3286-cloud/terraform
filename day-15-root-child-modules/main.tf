provider "aws" {
  region = var.region
}

module "vpc" {
  source     = "./vpc"
  cidr_block = var.vpc_cidr
  tags       = var.vpc_name
}

module "subnets" {
  source             = "./subnets"
  vpc_id             = module.vpc.vpc_id
  cidr_block         = var.subnet_cidr
  availability_zone  = var.subnet_az
}

module "security-group" {
  source = "./security-group"
  vpc_id = module.vpc.vpc_id
}

module "ec2" {
  source            = "./ec2"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = module.subnets.subnet_id
  security_group_id = module.security-group.security_group_id
  vpc_id            = module.vpc.vpc_id
}

