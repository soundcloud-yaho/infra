# 서울 프로덕션 환경 네트워크 실제 프로비저닝
# 운영계 전용 프라이빗 CIDR 대역폭 주입 및 서브넷 토폴로지 구체화


module "network" {
  source = "../../modules/network"

  project_name          = var.project_name
  environment           = var.environment
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  public_subnet_cidrs   = var.public_subnet_cidrs
  private_subnet_cidrs  = var.private_subnet_cidrs
  database_subnet_cidrs = var.database_subnet_cidrs
  enable_nat_gateway    = var.enable_nat_gateway
  cluster_name          = var.eks_cluster_name
}