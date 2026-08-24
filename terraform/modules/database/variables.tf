# [Database] 모듈 입력 변수
variable "project_name" {
  description = "프로젝트 이름 (예: soundcloud)"
  type        = string
}
variable "environment" {
  description = "배포 환경 (예: prod)"
  type        = string
}
variable "db_subnet_ids" {
  description = "RDS DB subnet group에 포함할 DB subnet ID"
  type        = list(string)
}
variable "security_group_id" {
  description = "RDS PostgreSQL 인바운드 허용 Security Group ID"
  type        = string
}
variable "kms_key_arn" {
  description = "RDS 저장 데이터 암호화용 KMS Key ARN"
  type        = string
  default     = null
}
variable "db_engine_version" {
  description = "RDS PostgreSQL engine version"
  type        = string
  default     = "17.11"
}
variable "parameter_group_family" {
  description = "RDS PostgreSQL parameter group family"
  type        = string
  default     = "postgres17"
}
variable "database_name" {
  description = "초기 생성할 PostgreSQL database 이름"
  type        = string
  default     = "worldcup"
}
variable "master_username" {
  description = "RDS master username"
  type        = string
  default     = "app_admin"
}
variable "db_instance_class" {
  description = "RDS PostgreSQL instance class"
  type        = string
  default     = "db.t4g.small"
}
variable "availability_zone" {
  description = "RDS instance를 배치할 단일 Availability Zone"
  type        = string
}
variable "allocated_storage" {
  description = "RDS 초기 storage 크기(GiB)"
  type        = number
  default     = 20
}
variable "max_allocated_storage" {
  description = "RDS storage autoscaling 상한(GiB)"
  type        = number
  default     = 100
}
