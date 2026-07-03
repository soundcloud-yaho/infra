# 서울 프로덕션 환경 EKS 클러스터 및 관제 노드그룹 프로비저닝

module "eks" {
  source = "../../modules/eks"

  cluster_name          = "${var.project_name}-${var.environment}-eks"
  cluster_version       = var.cluster_version
  private_subnet_ids    = module.network.private_subnet_ids
  system_instance_types = var.node_instance_types
  system_desired_size   = var.node_desired_size
}