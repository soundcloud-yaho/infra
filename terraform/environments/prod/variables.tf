# 프로덕션 인프라 구축에 동적으로 주입될 변수(Variables) 인터페이스 선언

# =====================================================
# Project Information
# 프로젝트 공통 정보
# =====================================================

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
}

# =====================================================
# Network Configuration
# VPC 및 네트워크 설정
# =====================================================

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
}

variable "availability_zones" {
  description = "사용할 가용 영역 목록"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 목록"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "프라이빗(EKS) 서브넷 CIDR 목록"
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "데이터베이스(Aurora) 서브넷 CIDR 목록"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "NAT Gateway 생성 여부"
  type        = bool
  default     = true
}

# =====================================================
# Security Configuration
# WAF / Security Group 설정
# =====================================================

variable "allowed_http_cidrs" {
  description = "ALB HTTP/HTTPS 접근 허용 CIDR"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# =====================================================
# Compute Configuration
# EKS 클러스터 설정
# =====================================================

variable "cluster_version" {
  description = "EKS Kubernetes 버전"
  type        = string
  default     = "1.31"
}

variable "node_instance_types" {
  description = "EKS Managed Node Group 인스턴스 타입"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "EKS NodeGroup Desired Size"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "EKS NodeGroup Minimum Size"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "EKS NodeGroup Maximum Size"
  type        = number
  default     = 3
}

# =====================================================
# Application Configuration
# 애플리케이션 설정
# =====================================================

variable "app_port" {
  description = "Application Port"
  type        = number
}

# =====================================================
# ECR Configuration
# 컨테이너 이미지 저장소 설정
# =====================================================

variable "ecr_repository_names" {
  description = "ECR Repository 이름 목록"
  type        = list(string)
}

# =====================================================
# Database Configuration
# Aurora PostgreSQL 설정
# =====================================================

variable "database_name" {
  description = "Database Name"
  type        = string
}

variable "master_username" {
  description = "Master Username"
  type        = string
}

variable "master_password" {
  description = "Master Password"
  type        = string
  sensitive   = true
}

variable "db_engine_version" {
  description = "Aurora PostgreSQL Engine Version"
  type        = string
}

variable "db_instance_class" {
  description = "Aurora Instance Class"
  type        = string
}