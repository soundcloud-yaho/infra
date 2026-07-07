module "security" {
  source = "../../modules/security"

  vpc_id       = module.network.vpc_id
  project_name = var.project_name
  environment  = var.environment
}