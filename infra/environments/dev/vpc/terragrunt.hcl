include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/vpc"
}

inputs = {
  cidr_block         = "10.0.0.0/16"
  environment        = "dev"
  enable_nat_gateway = false
}
