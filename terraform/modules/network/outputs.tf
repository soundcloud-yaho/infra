output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.this.cidr_block
}

output "internet_gateway_id" {
  description = "생성된 Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "데이터베이스 서브넷 ID 목록"
  value       = aws_subnet.database[*].id
}

output "nat_gateway_id" {
  description = "생성된 NAT Gateway ID"
  value       = try(aws_nat_gateway.this[0].id, null)
}