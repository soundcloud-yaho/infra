output "web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.this.arn
}

output "kms_key_id" {
  description = "KMS Key ID"
  value       = aws_kms_key.this.id
}

output "kms_key_arn" {
  description = "KMS Key ARN"
  value       = aws_kms_key.this.arn
}