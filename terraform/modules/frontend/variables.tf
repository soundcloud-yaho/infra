# [Frontend] 모듈 입력 변수
variable "project_name" {
  description = "프로젝트 이름 (예: soundcloud)"
  type        = string
}
variable "environment" {
  description = "배포 환경 (예: prod)"
  type        = string
}