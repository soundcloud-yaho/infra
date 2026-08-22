# [Network] 모듈 출력 값
output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
output "primary_private_subnet_ids" {
  description = "Single-AZ workload node용 primary private subnet ID"
  value = [
    aws_subnet.private[index(var.availability_zones, var.primary_availability_zone)].id
  ]
}
# db_subnet_ids → database_subnet_ids
output "database_subnet_ids" {
  value = aws_subnet.db[*].id
}
