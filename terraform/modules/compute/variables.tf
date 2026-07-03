variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "배포 환경"
  type        = string
}

variable "vpc_id" {
  description = "EKS가 생성될 VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "EKS NodeGroup이 사용할 Private Subnet ID 목록"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes 버전"
  type        = string
}

variable "eks_node_security_group_id" {
  description = "EKS Node Security Group"
  type        = string
}

variable "node_instance_types" {
  description = "EKS Managed Node Group 인스턴스 타입"
  type        = list(string)
}

variable "node_desired_size" {
  description = "EKS NodeGroup Desired Size"
  type        = number
}

variable "node_min_size" {
  description = "EKS NodeGroup Minimum Size"
  type        = number
}

variable "node_max_size" {
  description = "EKS NodeGroup Maximum Size"
  type        = number
}