# ECR Repository URL을 서비스별 output으로 제공

output "backend_repository_url" {
  value = aws_ecr_repository.this["backend"].repository_url
}

output "ai_repository_url" {
  value = aws_ecr_repository.this["ai"].repository_url
}

output "member_repository_url" {
  value = aws_ecr_repository.this["member"].repository_url
}

output "comment_repository_url" {
  value = aws_ecr_repository.this["comment"].repository_url
}

output "prediction_repository_url" {
  value = aws_ecr_repository.this["prediction"].repository_url
}