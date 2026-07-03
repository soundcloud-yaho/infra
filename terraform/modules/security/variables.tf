variable "vpc_id" {
  description = "WAF/ALB 보안 리소스가 연결될 VPC ID"
  type        = string
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
}