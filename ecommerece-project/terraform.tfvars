aws_region   = "us-east-1"
project_name = "ecommerce"
az_count     = 2

key_name    = "shiva"
domain_name = "tahirofficial.site"

# TODO: restrict this to your own IP before applying, e.g. "103.xx.xx.xx/32"
admin_ssh_cidr = "0.0.0.0/0"

# TODO: set a real password - do NOT commit this file with a real password to git.
# Better: leave this line out and run `terraform apply -var="db_password=YourRealPassword"`
# or export TF_VAR_db_password="YourRealPassword" before applying.
db_password = "PASSWORD123"

db_name     = "ecommercedb"
db_username = "admin"
