# 프로덕션 환경에 바인딩될 실제 운영 자원 데이터 세트

# =====================================================
# Project Information
# =====================================================

project_name = "soundcloud"
environment  = "prod"

# =====================================================
# Network Configuration
# =====================================================

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "ap-northeast-2a",
  "ap-northeast-2c"
]

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnet_cidrs = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

database_subnet_cidrs = [
  "10.0.21.0/24",
  "10.0.22.0/24"
]

enable_nat_gateway = true

# =====================================================
# Compute Configuration
# =====================================================

cluster_version = "1.31"

node_instance_types = ["t3.medium"]

node_desired_size = 2
node_min_size     = 1
node_max_size     = 3

# =====================================================
# Application Configuration
# =====================================================

app_port = 8080


# =====================================================
# ECR Configuration
# =====================================================

ecr_repository_names = [
  "backend",
  "ai"
]

# =====================================================
# Database Configuration
# =====================================================

database_name     = "worldcup"
master_username   = "postgres"
db_engine_version = "16.6"
db_instance_class = "db.t4g.medium"