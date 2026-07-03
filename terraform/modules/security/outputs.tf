# [Security] 모듈 출력 값
output "alb_security_group_id" {
  description = "-> Ingress 어노테이션 alb.ingress.kubernetes.io/security-groups"
  value       = aws_security_group.alb.id
}
output "eks_node_security_group_id" {
  description = "-> eks 모듈 추가 SG, Karpenter EC2NodeClass securityGroupSelectorTerms"
  value       = aws_security_group.eks_node.id
}
output "aurora_security_group_id" {
  description = "-> database 모듈의 aurora_security_group_id"
  value       = aws_security_group.aurora.id
}
output "lb_controller_role_arn" {
  description = "-> k8s/values/aws-lb-controller-values.yaml의 serviceAccount annotation"
  value       = aws_iam_role.lb_controller.arn
}