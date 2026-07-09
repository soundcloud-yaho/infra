# 컨테이너 이미지 저장을 위한 ECR Repository 프로비저닝

module "ecr" {
  source = "../../modules/ecr"

  project_name         = var.project_name
  environment          = var.environment
  ecr_repository_names = var.ecr_repository_names
}