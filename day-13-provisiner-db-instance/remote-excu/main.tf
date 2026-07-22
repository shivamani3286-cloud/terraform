provider "aws" {
  region = "us-east-1"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key for EC2 key pair"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  description = "Path to the SSH private key for SSH connection"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "db_host" {
  description = "RDS endpoint hostname"
  type        = string
  default     = ""

  validation {
    condition     = var.db_host != "" && var.db_host != "replace-with-rds-endpoint"
    error_message = "db_host must be set to the actual RDS endpoint hostname, not the placeholder value."
  }
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "dev"
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "Password123!"
}

resource "aws_key_pair" "example" {
  key_name   = "task"
  public_key = file(pathexpand(var.ssh_public_key_path))
}
# Example EC2 instance (replace with yours if already existing)
resource "aws_instance" "sql_runner" {
  ami                    = "ami-0b826bb6d96d2afe4" # Amazon Linux 2
  instance_type          = "t3.micro"
  key_name               = aws_key_pair.example.key_name         # Replace with your key pair name
  associate_public_ip_address = true

  tags = {
    Name = "SQL Runner"
  }
}

# Deploy SQL remotely using null_resource + remote-exec
resource "null_resource" "remote_sql_exec" {
  depends_on = [aws_instance.sql_runner]

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(pathexpand(var.ssh_private_key_path))
    host        = aws_instance.sql_runner.public_ip
  }

  provisioner "file" {
    source      = "../local-excu/init.sql"
    destination = "/tmp/init.sql"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum makecache fast || true",
      "sudo yum install -y mariadb-server || sudo yum install -y mariadb105-server || sudo yum install -y mariadb || true",
      "mysql --version || true",
      "mysql -h ${var.db_host} -u ${var.db_user} -p${var.db_password} ${var.db_name} < /tmp/init.sql"
    ]
  }

  triggers = {
    always_run = timestamp() #trigger every time apply 
  }
}




# ADD RDS creation script only accessbale interanlly si disable public access 
# Remote provisioner server also should create insame vpc 
# enable secrets fro secret manager and call secrets into RDS for this process vpc endpoint is require or nat gateway is required to access secrets to rds internall as secremanger is not in side VPC sefrvice 