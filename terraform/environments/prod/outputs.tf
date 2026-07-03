# 프로덕션 환경 주요 Terraform Output

output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public Subnet IDs"
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private Subnet IDs"
  value       = module.network.private_subnet_ids
}

output "database_subnet_ids" {
  description = "Database Subnet IDs"
  value       = module.network.database_subnet_ids
}

output "eks_cluster_name" {
  description = "EKS Cluster Name"
  value       = module.compute.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS Cluster Endpoint"
  value       = module.compute.cluster_endpoint
}

output "eks_oidc_issuer" {
  description = "EKS OIDC Issuer URL"
  value       = module.compute.oidc_issuer
}

output "backend_repository_url" {
  value = module.ecr.backend_repository_url
}

output "ai_repository_url" {
  value = module.ecr.ai_repository_url
}

output "aurora_writer_endpoint" {
  description = "Aurora Writer Endpoint"
  value       = module.database.writer_endpoint
}

output "aurora_reader_endpoint" {
  description = "Aurora Reader Endpoint"
  value       = module.database.reader_endpoint
}

output "aurora_master_user_secret_arn" {
  description = "Aurora Master User Secret ARN"
  value       = module.database.master_user_secret_arn
  sensitive   = true
}

output "kms_key_arn" {
  description = "KMS Key ARN"
  value       = module.security.kms_key_arn
}

output "web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = module.security.web_acl_arn
}