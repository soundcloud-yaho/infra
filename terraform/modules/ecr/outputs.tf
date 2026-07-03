# repository_urls 맵 → 개별 output으로 분리
output "backend_repository_url" {
  value = aws_ecr_repository.this["backend"].repository_url
}
output "ai_repository_url" {
  value = aws_ecr_repository.this["ai"].repository_url
}