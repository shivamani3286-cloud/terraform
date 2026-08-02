variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "enable_nat_gateway" {
  type        = bool
  default     = false
  description = "Whether to create a NAT Gateway"
}
