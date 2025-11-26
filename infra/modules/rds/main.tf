resource "aws_db_subnet_group" "this" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "this" {
  identifier = "${replace(lower(var.db_name), "_", "-")}-instance"
  engine                   = "postgres"
  engine_version           = "14.19"
  instance_class           = "db.t3.micro"
  allocated_storage        = 20
  username                 = var.db_username
  password                 = var.db_password
  db_name                  = var.db_name
  port                     = 5432
  skip_final_snapshot      = true
  storage_encrypted        = false
  publicly_accessible      = false
  multi_az                 = false

  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.this.name
}
