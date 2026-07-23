variable "port_cidr_rules" {
  description = "List of ingress rules with port and CIDR block mappings."
  type = list(object({
    port       = number
    cidr_block = string
  }
  )
  )
}

