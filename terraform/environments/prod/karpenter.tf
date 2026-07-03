# [호출] karpenter 모듈 - eks 출력(OIDC/SG)을 받아 IAM/SQS 생성
module "karpenter" {
  source                    = "../../modules/karpenter"
  cluster_name              = module.eks.cluster_name
  cluster_security_group_id = module.eks.cluster_security_group_id
  oidc_provider_arn         = module.eks.oidc_provider_arn
  oidc_issuer               = module.eks.oidc_issuer
}
