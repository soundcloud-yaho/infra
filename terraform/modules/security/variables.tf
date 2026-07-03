# [Security] 모듈 입력 변수
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}
variable "environment" {
  description = "배포 환경"
  type        = string
}
variable "vpc_id" {
  description = "SG를 생성할 VPC ID"
  type        = string
}
variable "eks_cluster_security_group_id" {
  description = "EKS 클러스터 SG ID - Aurora 인바운드 소스로 사용"
  type        = string
}
variable "oidc_provider_arn" {
  description = "IRSA용 OIDC 프로바이더 ARN"
  type        = string
}
variable "oidc_issuer" {
  description = "https:// 제거된 OIDC issuer URL"
  type        = string
}
variable "app_port" {
  description = "FastAPI 컨테이너 포트 - ALB에서 EKS 노드로 허용할 포트"
  type        = number
  default     = 8080
}