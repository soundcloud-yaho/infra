# [Database] Single-AZ RDS PostgreSQL

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-database"
  subnet_ids = var.db_subnet_ids
}

resource "aws_db_parameter_group" "this" {
  name   = "${var.project_name}-${var.environment}-postgres-pg"
  family = var.parameter_group_family

  parameter {
    name  = "timezone"
    value = "Asia/Seoul"
  }
}

resource "aws_db_instance" "this" {
  identifier = "${var.project_name}-${var.environment}-postgres"

  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"

  db_name                     = var.database_name
  username                    = var.master_username
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  parameter_group_name   = aws_db_parameter_group.this.name
  vpc_security_group_ids = [var.security_group_id]
  publicly_accessible    = false

  multi_az          = false
  availability_zone = var.availability_zone

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  backup_retention_period = 1
  skip_final_snapshot     = true
}
