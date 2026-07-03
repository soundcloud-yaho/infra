# [호출] eks 모듈 - network의 프라이빗 서브넷을 받아 클러스터 생성
module "eks" {
  source             = "../../modules/eks"
  cluster_name       = var.cluster_name
  private_subnet_ids = module.network.private_subnet_ids
}
