##############################################
# GENERAL
##############################################

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used to name/tag all resources"
  type        = string
  default     = "ecommerce"
}

variable "az_count" {
  description = "Number of Availability Zones to use"
  type        = number
  default     = 2
}

##############################################
# NETWORKING
##############################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (Bastion + Frontend ALB + NAT), one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "frontend_subnet_cidrs" {
  description = "CIDR blocks for private frontend app subnets (Frontend ASG), one per AZ"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "backend_subnet_cidrs" {
  description = "CIDR blocks for private backend app subnets (Backend ASG + internal ALB), one per AZ"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "db_subnet_cidrs" {
  description = "CIDR blocks for private DB subnets (RDS), one per AZ"
  type        = list(string)
  default     = ["10.0.31.0/24", "10.0.32.0/24"]
}

variable "admin_ssh_cidr" {
  description = "CIDR allowed to SSH into the bastion host on port 22. Restrict this to your own IP, e.g. 1.2.3.4/32"
  type        = string
  default     = "0.0.0.0/0"
}

##############################################
# EC2 / KEY PAIR
##############################################

variable "key_name" {
  description = "Existing EC2 key pair name used for SSH access"
  type        = string
  default     = "shiva"
}

variable "bastion_instance_type" {
  description = "Instance type for the bastion host"
  type        = string
  default     = "t3.micro"
}

variable "frontend_instance_type" {
  description = "Instance type for frontend app servers"
  type        = string
  default     = "t3.micro"
}

variable "backend_instance_type" {
  description = "Instance type for backend app servers"
  type        = string
  default     = "t3.micro"
}

variable "frontend_app_port" {
  description = "Port the frontend application listens on (behind the frontend ALB)"
  type        = number
  default     = 3000
}

variable "backend_app_port" {
  description = "Port the backend application listens on (behind the internal backend ALB)"
  type        = number
  default     = 5000
}

##############################################
# AUTO SCALING
##############################################

variable "frontend_asg_min" {
  type    = number
  default = 1
}

variable "frontend_asg_max" {
  type    = number
  default = 3
}

variable "frontend_asg_desired" {
  type    = number
  default = 2
}

variable "backend_asg_min" {
  type    = number
  default = 1
}

variable "backend_asg_max" {
  type    = number
  default = 3
}

variable "backend_asg_desired" {
  type    = number
  default = 2
}

##############################################
# RDS
##############################################

variable "db_engine_version" {
  description = "MySQL engine version"
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class for primary DB"
  type        = string
  default     = "db.t3.micro"
}

variable "db_replica_instance_class" {
  description = "RDS instance class for the read replica"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "ecommercedb"
}

variable "db_username" {
  description = "Master username for RDS"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for RDS. Override this in terraform.tfvars or via TF_VAR_db_password - do not commit a real password to git."
  type        = string
  sensitive   = true
}

##############################################
# DOMAIN / TLS / EDGE
##############################################

variable "domain_name" {
  description = "Root domain name, e.g. tahirofficial.site"
  type        = string
  default     = "tahirofficial.site"
}

variable "create_route53_zone" {
  description = "Set to true only if the Route53 hosted zone for domain_name does NOT already exist. If it already exists (as in this project), leave false and Terraform will look it up instead."
  type        = bool
  default     = false
}
