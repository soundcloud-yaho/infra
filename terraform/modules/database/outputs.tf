# [Database] 모듈 출력 값 - backend의 K8s Secret 생성 시 사용
output "writer_endpoint" {
  description = "쓰기 전용 - 동기화 CronJob이 사용"
  value       = aws_rds_cluster.this.endpoint
}
output "reader_endpoint" {
  description = "읽기 전용 - FastAPI가 사용 (reader 0개면 writer로 자동 연결됨)"
  value       = aws_rds_cluster.this.reader_endpoint
}
output "database_name" {
  description = "DB 이름 - K8s Secret의 DB_NAME 값"
  value       = aws_rds_cluster.this.database_name
}
