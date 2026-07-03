# [ECR] 모듈 출력 값 - CI 워크플로우와 deployment.yaml 이미지 경로에 사용
output "repository_urls" {
  value = { for k, v in aws_ecr_repository.this : k => v.repository_url }
}
