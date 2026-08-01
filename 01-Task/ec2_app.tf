locals {
  app_userdata = templatefile("${path.module}/templates/app-userdata.sh.tpl", {})
}

resource "aws_instance" "app" {
  count                  = var.app_server_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.app_instance_type
  key_name               = aws_key_pair.generated.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data                   = local.app_userdata
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-app-server-${count.index + 1}"
  }
}
