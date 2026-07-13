# [EKS] 모듈 출력 값 - karpenter/security 모듈과 k8s values가 참조
output "cluster_name" {
  description = "EKS 클러스터 이름 - karpenter 모듈의 cluster_name 변수로 전달"
  value       = aws_eks_cluster.this.name
}
output "cluster_endpoint" {
  description = "EKS API 서버 엔드포인트 - kubeconfig 및 prod outputs에서 참조"
  value       = aws_eks_cluster.this.endpoint
}
output "cluster_security_group_id" {
  description = "EKS가 자동 생성한 클러스터 SG - Karpenter discovery 태그를 여기 붙임"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
output "oidc_provider_arn" { value = aws_iam_openid_connect_provider.this.arn }

output "oidc_issuer" {
  description = "https:// 제거된 issuer - IRSA 신뢰 정책 조건에 사용"
  value       = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "") 
}
output "ebs_csi_driver_role_arn" {
  description = "EBS CSI Driver IRSA role ARN - 디버깅/확인용"
  value       = aws_iam_role.ebs_csi_driver.arn
}