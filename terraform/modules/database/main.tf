# [Database] Aurora PostgreSQL - Writer + Reader, 공유 스토리지 구조
# Aurora는 인스턴스가 아니라 "클러스터(스토리지) + 인스턴스(연산)"로 나뉜다

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-${var.environment}-aurora"
  subnet_ids = var.db_subnet_ids
}

resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.project_name}-${var.environment}-aurora-cluster-pg"
  family = var.parameter_group_family

  parameter {
    name  = "timezone"
    value = "Asia/Seoul" # AIDAS에서 겪은 UTC/KST 불일치 재발 방지
  }
}

resource "aws_rds_cluster" "this" {
  cluster_identifier              = "${var.project_name}-${var.environment}-aurora"
  engine                          = "aurora-postgresql"
  engine_version                  = var.db_engine_version      # engine_version → db_engine_version
  database_name                   = var.database_name
  master_username                 = var.master_username
  manage_master_user_password = true
  db_subnet_group_name            = aws_db_subnet_group.this.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name
  vpc_security_group_ids          = [var.security_group_id]    # aurora_security_group_id → security_group_id
  storage_encrypted               = true
  kms_key_id                      = var.kms_key_arn            # null이면 AWS 기본 암호화
  skip_final_snapshot             = true
  backup_retention_period         = 1
}

resource "aws_rds_cluster_instance" "writer" {
  identifier         = "${var.project_name}-${var.environment}-aurora-writer"
  cluster_identifier = aws_rds_cluster.this.id
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
  instance_class     = var.db_instance_class                   # instance_class → db_instance_class
}

resource "aws_rds_cluster_instance" "reader" {
  count              = var.reader_count
  identifier         = "${var.project_name}-${var.environment}-aurora-reader-${count.index}"
  cluster_identifier = aws_rds_cluster.this.id
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
  instance_class     = var.db_instance_class                   # instance_class → db_instance_class

  depends_on = [aws_rds_cluster_instance.writer]
}