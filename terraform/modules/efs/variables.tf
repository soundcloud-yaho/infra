variable "vpc_id" {
  description = "EFS 마운트 타겟을 생성할 VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "EFS 마운트 타겟을 생성할 프라이빗 서브넷 ID 목록"
  type        = list(string)
}

variable "node_security_group_id" {
  description = "EKS 노드 보안그룹 ID — NFS(2049) 인바운드 허용 대상"
  type        = string
}

variable "project_name" {
  description = "리소스 네이밍/태깅용 프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "리소스 네이밍/태깅용 환경 이름"
  type        = string
}