output "cluster_id" {
  description = "Aurora Cluster ID"
  value       = aws_rds_cluster.this.id
}

output "writer_endpoint" {
  description = "Aurora Writer Endpoint"
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Aurora Reader Endpoint"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "database_name" {
  description = "Database Name"
  value       = var.database_name
}

output "master_user_secret_arn" {
  description = "Aurora Master User Secret ARN"
  value       = aws_rds_cluster.this.master_user_secret[0].secret_arn
}