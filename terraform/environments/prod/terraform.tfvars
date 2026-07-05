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
  "10.0.32.0/19",
  "10.0.64.0/19"
]

database_subnet_cidrs = [
  "10.0.21.0/24",
  "10.0.22.0/24"
]


# =====================================================
# Compute Configuration
# =====================================================

  cluster_version = "1.33"

system_instance_types = ["t3.medium"]
system_desired_size = 2
system_min_size = 2
system_max_size = 3

ai_instance_types = ["m5.large"]
ai_desired_size   = 1
ai_min_size       = 1
ai_max_size       = 2

worker_instance_types = ["t3.medium"]
worker_desired_size   = 1
worker_min_size       = 1
worker_max_size       = 2
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