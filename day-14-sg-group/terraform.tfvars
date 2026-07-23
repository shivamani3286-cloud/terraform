port_cidr_rules = [
  {
    port       = 80
    cidr_block = "0.0.0.0/0"
  },
  {
    port       = 443
    cidr_block = "10.0.1.0/24"
  },
  {
    port       = 8080
    cidr_block = "172.16.0.0/16"
  },
  {
    port       = 9000
    cidr_block = "192.168.1.0/24"
  },
  {
    port       = 3000
    cidr_block = "203.0.113.0/24"
  },
  {
    port       = 8082
    cidr_block = "198.51.100.0/24"
  },
  {
    port       = 8081
    cidr_block = "169.254.0.0/16"
  },
]

