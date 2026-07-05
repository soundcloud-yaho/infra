variable "project_name" {
  description = "프로젝트 이름 (예: soundcloud)"
  type        = string
}
variable "environment" {
  description = "배포 환경 (예: prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS 클러스터 이름 - karpenter.sh/discovery 태그 값으로 사용"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR 대역"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "사용할 가용영역 2개 (ALB 생성 최소 요건)"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR - ALB, NAT Gateway 배치"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}
variable "private_subnet_cidrs" {
  description = "워커 노드/Pod가 IP를 받는 대역 - VPC CNI는 Pod마다 실제 IP를 쓰므로 넉넉하게"
  type        = list(string)
  default     = ["10.0.32.0/19", "10.0.64.0/19"]
}
variable "database_subnet_cidrs" {
  description = "DB 서브넷 CIDR - Aurora 전용, 인터넷 경로 없음"
  type        = list(string)
  default     = ["10.0.96.0/24", "10.0.97.0/24"]
}