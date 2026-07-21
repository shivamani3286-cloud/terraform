variable "cidr_block" {
    description = "The CIDR block for the VPC"
    type = string
    default = ""
}
variable "tag" {
    description = "The tag for the VPC"
    type = string
    default = ""
}
variable "cidr_block_vpc-2" {
    description = "The CIDR block for the VPC"
    type = string
    default = ""
}
variable "cidr_block_subnet" {
    description = "The CIDR block for the subnet"
    type = string
    default = ""
}

variable "tag_subnet" {
    description = "The tag for the subnet tag"
    type = string
    default = "veera"
}
variable "bucket_name" {
    description = "The name of the S3 bucket"
    type = string
    default = ""
}