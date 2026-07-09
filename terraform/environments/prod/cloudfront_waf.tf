# CloudFront용 WAF 모듈 호출

module "waf" {
  source = "../../modules/waf"

  providers = {
    aws = aws.virginia
  }

  project_name = var.project_name
  environment  = var.environment
}