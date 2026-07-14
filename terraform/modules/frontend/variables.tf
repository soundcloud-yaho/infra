# [Frontend] 모듈 입력 변수
variable "project_name" {
  description = "프로젝트 이름 (예: soundcloud)"
  type        = string
}
variable "environment" {
  description = "배포 환경 (예: prod)"
  type        = string
}

variable "web_acl_id" {
  description = "CloudFront에 연결할 WAF ARN"
  type        = string
  default     = null
}

variable "aliases" {
  type = list(string)
}

variable "acm_certificate_arn" {
  type = string
}