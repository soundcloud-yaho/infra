# [Karpenter] 모듈 입력 변수 - 전부 eks 모듈 출력에서 넘어온다
variable "cluster_name" {
  description = "EKS 클러스터 이름 - SQS 큐 이름과 반드시 일치해야 함"
  type        = string
}
variable "cluster_security_group_id" {
  description = "EKS 클러스터 SG ID - discovery 태그 부착 대상"
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