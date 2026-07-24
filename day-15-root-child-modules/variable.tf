variable "region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = ""
}

variable "vpc_name" {
  type    = string
  default = ""
}

variable "subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "subnet_az" {
  type    = string
  default = "us-east-1a"
}

variable "ami_id" {
  type        = string
  default     = ""
  description = "AMI ID for EC2 instances"
}

variable "instance_type" {
  type        = string
  default     = ""
  description = "EC2 instance type"
}
