resource "aws_db_subnet_group" "rds" {
  name       = var.subnet_group_name
  subnet_ids = var.subnet_ids

  tags = {
    Name = var.subnet_group_name
  }
}

resource "aws_db_instance" "rds" {
  identifier             = var.db_identifier
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage

  username               = var.username
  password               = var.password

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = var.security_group_ids

  publicly_accessible    = var.publicly_accessible
  skip_final_snapshot    = true

  tags = {
    Name = var.db_identifier
  }
}