# [호출] ecr 모듈
module "ecr" {
  source = "../../modules/ecr"
  name   = var.name
}
