# 전방 웹 방화벽(WAF) 및 Application Load Balancer(ALB) 인프라 연동

module "security" {
  source = "../../modules/security"

  vpc_id       = module.network.vpc_id
  project_name = var.project_name
  environment  = var.environment
}