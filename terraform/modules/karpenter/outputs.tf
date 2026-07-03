# [Karpenter] 모듈 출력 값 - k8s/values/karpenter-values.yaml과 ec2nodeclass.yaml에 복사할 값들
output "controller_role_arn" {
  description = "-> karpenter-values.yaml의 serviceAccount annotation"
  value       = aws_iam_role.controller.arn
}
output "node_role_name" {
  description = "-> ec2nodeclass.yaml의 spec.role"
  value       = aws_iam_role.node.name
}
output "interruption_queue_name" {
  description = "-> karpenter-values.yaml의 settings.interruptionQueue"
  value       = aws_sqs_queue.interruption.name
}
