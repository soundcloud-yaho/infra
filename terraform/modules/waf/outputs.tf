# WAF 모듈에서 생성한 주요 값을 외부로 전달
# CloudFront 모듈에서 Web ACL ARN을 받아 WAF를 연결할 수 있도록 output으로 제공


output "web_acl_arn" {
  description = "CloudFront WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.cloudfront.arn
}

output "web_acl_id" {
  description = "CloudFront WAF Web ACL ID"
  value       = aws_wafv2_web_acl.cloudfront.id
}

output "waf_log_bucket_name" {
  description = "S3 bucket name for WAF logs"
  value       = aws_s3_bucket.waf_logs.bucket
}

output "waf_log_bucket_arn" {
  description = "S3 bucket ARN for WAF logs"
  value       = aws_s3_bucket.waf_logs.arn
}