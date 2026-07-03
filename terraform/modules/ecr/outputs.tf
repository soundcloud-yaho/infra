output "repository_urls" {
  description = "ECR Repository URL 목록"
  value = {
    for name, repo in aws_ecr_repository.this :
    name => repo.repository_url
  }
}

output "repository_arns" {
  description = "ECR Repository ARN 목록"
  value = {
    for name, repo in aws_ecr_repository.this :
    name => repo.arn
  }
}

output "backend_repository_url" {
  description = "Backend ECR Repository URL"
  value       = aws_ecr_repository.this["backend"].repository_url
}

output "ai_repository_url" {
  description = "AI ECR Repository URL"
  value       = aws_ecr_repository.this["ai"].repository_url
}