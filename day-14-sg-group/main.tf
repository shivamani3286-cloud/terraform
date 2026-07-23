resource "aws_security_group" "name" {
  name        = "my-sg"
  description = "allow-all"

  ingress = [
    for rule in var.port_cidr_rules : {
      description      = "inbound rule for port ${rule.port}"
      from_port        = rule.port
      to_port          = rule.port
      protocol         = "tcp"
      cidr_blocks      = [rule.cidr_block]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
}
