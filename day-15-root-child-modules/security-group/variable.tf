variable "vpc_id" {
  type        = string
  description = "ID of the VPC to attach the subnet to"
}
variable "sg_name" {
    type = string
    default = ""
    description = "nameforsg"
  
}

variable "sg_description" {
  type    = string
  default = "Security group for shiva instances"
  description = "descriptionforsg"
}

variable "sg_cidr_blocks" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "cidr blocks for sg"
}
