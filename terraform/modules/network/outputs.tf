# [Network] 모듈 출력 값
output "vpc_id" { value = aws_vpc.this.id }
output "public_subnet_ids" { value = aws_subnet.public[*].id }
output "private_subnet_ids" { value = aws_subnet.private[*].id }
# db_subnet_ids → database_subnet_ids
output "database_subnet_ids" {
  value = aws_subnet.db[*].id
}
