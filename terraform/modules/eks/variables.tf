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
  description = "System 노드그룹 인스턴스 타입"
  type        = list(string)
  default     = ["t3.medium"]
}
variable "system_desired_size" {
  description = "System 노드그룹 desired 노드 수"
  type        = number
  default     = 2
}
variable "system_min_size" {
  description = "System 노드그룹 최소 노드 수"
  type        = number
  default     = 2
}
variable "system_max_size" {
  description = "System 노드그룹 최대 노드 수"
  type        = number
  default     = 3
}

# ---------- AI 노드그룹 변수 ----------
variable "ai_instance_types" {
  description = "AI 노드그룹 인스턴스 타입 - 메모리 위주 (NeuralProphet 학습용)"
  type        = list(string)
  default     = ["m5.large"]
}
variable "ai_desired_size" {
  description = "AI 노드그룹 desired 노드 수"
  type        = number
  default     = 1
}
variable "ai_min_size" {
  description = "AI 노드그룹 최소 노드 수"
  type        = number
  default     = 1
}
variable "ai_max_size" {
  description = "AI 노드그룹 최대 노드 수"
  type        = number
  default     = 2
}

# ---------- Worker 노드그룹 변수 ----------
variable "worker_instance_types" {
  description = "Worker 노드그룹 인스턴스 타입 - FastAPI 베이스라인"
  type        = list(string)
  default     = ["t3.medium"]
}
variable "worker_desired_size" {
  description = "Worker 노드그룹 desired 노드 수"
  type        = number
  default     = 1
}
variable "worker_min_size" {
  description = "Worker 노드그룹 최소 노드 수"
  type        = number
  default     = 1
}
variable "worker_max_size" {
  description = "Worker 노드그룹 최대 노드 수"
  type        = number
  default     = 2
}