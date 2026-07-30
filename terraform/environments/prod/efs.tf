module "efs_prophet" {
  source = "../../modules/efs"

  project_name = var.project_name
  environment  = var.environment

  vpc_id                 = module.network.vpc_id
  private_subnet_ids     = module.network.private_subnet_ids
  node_security_group_id = module.security.eks_node_security_group_id
}

output "efs_prophet_file_system_id" {
  value = module.efs_prophet.file_system_id
}