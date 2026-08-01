resource "tls_private_key" "monitoring_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.monitoring_key.public_key_openssh
}

# Saved locally so you can SSH in. Keep this file safe - it's a real private key.
resource "local_file" "private_key" {
  content         = tls_private_key.monitoring_key.private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0400"
}
