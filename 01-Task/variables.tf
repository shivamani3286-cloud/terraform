variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Name prefix used for tagging all resources"
  type        = string
  default     = "monitoring"
}

variable "vpc_cidr" {
  description = "CIDR block for the auto-created VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the auto-created public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type for the monitoring server"
  type        = string
  default     = "t3.micro"
}

variable "app_instance_type" {
  description = "EC2 instance type for the sample application servers"
  type        = string
  default     = "t3.micro"
}

variable "app_server_count" {
  description = "How many sample application servers to create (each runs node_exporter)"
  type        = number
  default     = 1
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH into instances. Restrict this to your own IP/32 before using this for real."
  type        = string
  default     = "0.0.0.0/0"
}

variable "web_allowed_cidr" {
  description = "CIDR allowed to reach the Grafana/Prometheus web UIs. Restrict this to your own IP/32 before using this for real."
  type        = string
  default     = "0.0.0.0/0"
}

variable "grafana_admin_password" {
  description = "Initial Grafana admin password"
  type        = string
  default     = "ChangeMe123!"
  sensitive   = true
}
