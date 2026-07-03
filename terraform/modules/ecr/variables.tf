variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
}

variable "repository_names" {
  description = "ECR Repository 이름 목록"
  type        = list(string)
}