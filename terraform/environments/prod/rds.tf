# 서울 프로덕션 단일 RDS PostgreSQL instance 프로비저닝

module "database" {
  source = "../../modules/database"

  project_name = var.project_name
  environment  = var.environment

  db_subnet_ids     = module.network.database_subnet_ids
  security_group_id = module.security.aurora_sg_id
  kms_key_arn       = module.security.kms_key_arn

  database_name     = var.database_name
  master_username   = var.master_username
  db_engine_version = var.db_engine_version
  db_instance_class = var.db_instance_class
  availability_zone = var.primary_availability_zone
}
