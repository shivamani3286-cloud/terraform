variable "ami_id" {
  type        = string
  default     = ""
  description = "AMI ID for the EC2 instance"
}

variable "instance_type" {
  type        = string
  default     = "t2.micro"
  description = "EC2 instance type"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet for the EC2 instance"
}

variable "security_group_id" {
  type        = string
  description = "Security group ID for the EC2 instance"
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC for the EC2 instance"
}

