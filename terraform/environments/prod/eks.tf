# 서울 프로덕션 환경 EKS 클러스터 및 관제 노드그룹 프로비저닝

module "compute" {
  source = "../../modules/compute"

  vpc_id     = module.network.vpc_id
  subnet_ids = module.network.private_subnet_ids

  project_name               = var.project_name
  environment                = var.environment
  cluster_name               = "${var.project_name}-${var.environment}-eks"
  cluster_version            = var.cluster_version
  eks_node_security_group_id = aws_security_group.eks_node.id

  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}