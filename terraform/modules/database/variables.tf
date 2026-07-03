# [Database] 모듈 입력 변수
variable "project_name" {
  description = "프로젝트 이름 (예: soundcloud)"
  type        = string
}
variable "environment" {
  description = "배포 환경 (예: prod)"
  type        = string
}
variable "vpc_id" {
  description = "Aurora가 배포될 VPC ID"
  type        = string
}
variable "db_subnet_ids" {
  description = "Aurora 전용 DB 서브넷 ID - network 모듈 output에서 전달"
  type        = list(string)
}
variable "security_group_id" {
  description = "Aurora 인바운드 허용 SG ID - security 모듈 output에서 전달"
  type        = string
}
variable "kms_key_arn" {
  description = "Aurora 저장 데이터 암호화용 KMS 키 ARN"
  type        = string
  default     = null  # null이면 AWS 기본 암호화 사용
}
variable "db_engine_version" {
  description = "Aurora PostgreSQL 버전 - apply 전 aws rds describe-db-engine-versions로 확인"
  type        = string
  default     = "16.6"
}
variable "parameter_group_family" {
  description = "Aurora 파라미터 그룹 패밀리"
  type        = string
  default     = "aurora-postgresql16"
}
variable "database_name" {
  description = "Aurora 데이터베이스 이름"
  type        = string
  default     = "worldcup"
}
variable "master_username" {
  description = "Aurora 마스터 계정명 - 생성 후 변경 불가, FastAPI DB_USER와 반드시 일치"
  type        = string
  default     = "app_admin"
}
variable "master_password" {
  description = "tfvars에 절대 평문 저장 금지 - export TF_VAR_db_master_password=... 로 주입"
  type        = string
  sensitive   = true
}
variable "db_instance_class" {
  description = "Aurora 인스턴스 사양 - 데모 규모용 최소 사양"
  type        = string
  default     = "db.t4g.medium"
}
variable "reader_count" {
  description = "Reader 개수 - 비용 아끼려면 0으로 시작, 시연 때 1로"
  type        = number
  default     = 1
}