variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnet_ids" {
  description = "Aurora DB Subnet IDs"
  type        = list(string)
}

variable "security_group_id" {
  description = "Aurora Security Group ID"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS Key ARN for Aurora and Secrets Manager"
  type        = string
}

variable "database_name" {
  description = "Database Name"
  type        = string
}

variable "master_username" {
  description = "Master Username"
  type        = string
}

variable "db_engine_version" {
  description = "Aurora PostgreSQL Engine Version"
  type        = string
}

variable "db_instance_class" {
  description = "Aurora Instance Class"
  type        = string
}