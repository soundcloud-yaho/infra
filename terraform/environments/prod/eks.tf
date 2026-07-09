# 서울 프로덕션 환경 EKS 클러스터 및 관제 노드그룹 프로비저닝

module "eks" {
  source = "../../modules/eks"

  cluster_name        = var.cluster_name
  cluster_version     = var.cluster_version
  private_subnet_ids  = module.network.private_subnet_ids

  # System 노드그룹
  system_instance_types = var.system_instance_types
  system_desired_size   = var.system_desired_size
  system_min_size       = var.system_min_size
  system_max_size       = var.system_max_size

  # AI 노드그룹
  ai_instance_types = var.ai_instance_types
  ai_desired_size   = var.ai_desired_size
  ai_min_size       = var.ai_min_size
  ai_max_size       = var.ai_max_size

  # Worker 노드그룹
  worker_instance_types = var.worker_instance_types
  worker_desired_size   = var.worker_desired_size
  worker_min_size       = var.worker_min_size
  worker_max_size       = var.worker_max_size
}
