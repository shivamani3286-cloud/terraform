variable "vpc_id" {
  type        = string
  description = "ID of the VPC to attach the subnet to"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the subnet"
}

variable "availability_zone" {
  type        = string
  default     = "us-east-1a"
  description = "Availability zone for the subnet"
}
