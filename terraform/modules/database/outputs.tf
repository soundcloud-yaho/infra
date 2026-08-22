# [Database] 모듈 출력 값
output "database_host" {
  description = "단일 RDS PostgreSQL instance hostname"
  value       = aws_db_instance.this.address
}
output "database_name" {
  description = "초기 생성한 PostgreSQL database 이름"
  value       = aws_db_instance.this.db_name
}
output "master_user_secret_arn" {
  description = "RDS master password를 관리하는 Secrets Manager Secret ARN"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
  sensitive   = true
}
