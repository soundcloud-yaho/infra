output "file_system_id" {
  description = "Prophet용 EFS 파일시스템 ID"
  value       = aws_efs_file_system.prophet_model.id
}

output "security_group_id" {
  description = "EFS 보안그룹 ID"
  value       = aws_security_group.efs_prophet.id
}