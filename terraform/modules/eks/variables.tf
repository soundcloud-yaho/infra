# [EKS] 모듈 입력 변수
variable "cluster_name" {
  description = "EKS 클러스터 이름 (예: soundcloud-prod-eks)"
  type        = string
}

variable "cluster_version" {
  description = "EKS 버전 - apply 전 aws eks describe-addon-versions 등으로 최신 지원 버전 확인"
  type        = string
  default     = "1.33"
}

variable "private_subnet_ids" {
  description = "워커 노드가 배치될 프라이빗 서브넷 ID - network 모듈 output에서 전달"
  type        = list(string)
}

variable "system_instance_types" {
  description = "System 노드그룹 인스턴스 타입 - 관제 파드(Prometheus 등)가 무거우면 t3.large로"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "system_desired_size" {
  description = "System 노드그룹 노드 수 - 최소 2개 권장 (단일 장애점 방지)"
  type        = number
  default     = 2
}