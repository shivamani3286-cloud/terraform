include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  cidr_block         = "10.1.0.0/16"
  environment        = "prod"
  enable_nat_gateway = true
}
