# [Database 코어 모듈] Aurora PostgreSQL 클러스터 구현
# - DB Subnet Group 기반 Aurora PostgreSQL Writer / Reader 구성
# - Master Password는 Secrets Manager에서 자동 생성 및 관리
# - Aurora Storage 및 Secret 암호화에 KMS Key 연동

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-db-subnet"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.project_name}-${var.environment}-aurora"

  engine         = "aurora-postgresql"
  engine_version = var.db_engine_version

  database_name   = var.database_name
  master_username = var.master_username

  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_arn

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.security_group_id]

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  backup_retention_period = 7
  skip_final_snapshot     = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-aurora"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.project_name}-${var.environment}-aurora-writer"
  cluster_identifier = aws_rds_cluster.this.id

  instance_class = var.db_instance_class

  engine         = aws_rds_cluster.this.engine
  engine_version = aws_rds_cluster.this.engine_version
}

resource "aws_rds_cluster_instance" "reader" {
  identifier         = "${var.project_name}-${var.environment}-aurora-reader"
  cluster_identifier = aws_rds_cluster.this.id

  instance_class = var.db_instance_class

  engine         = aws_rds_cluster.this.engine
  engine_version = aws_rds_cluster.this.engine_version
}