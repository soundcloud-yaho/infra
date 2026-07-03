# [호출] security 모듈 - Aurora SG 체인 + LB Controller IRSA
module "security" {
  source            = "../../modules/security"
  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_issuer       = module.eks.oidc_issuer
  app_port          = var.app_port
}