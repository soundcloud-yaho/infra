# [Frontend] 모듈 출력 값 - frontend 레포 CI 워크플로우(S3 sync, invalidation)에 필요
output "bucket_name" {
  description = "S3 버킷 이름 - frontend CI s3 sync 대상"
  value       = aws_s3_bucket.frontend.id
}
output "cloudfront_distribution_id" {
  description = "CloudFront 배포 ID - CI invalidation 대상"
  value       = aws_cloudfront_distribution.frontend.id
}
output "cloudfront_domain_name" {
  description = "Route 53에서 이 도메인으로 CNAME/ALIAS 연결"
  value       = aws_cloudfront_distribution.frontend.domain_name
}
output "deploy_policy_arn" {
  description = "CI용 IAM 유저/Role에 attach"
  value       = aws_iam_policy.frontend_deploy.arn
}
