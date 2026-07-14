# [호출] frontend 모듈 - S3 정적 호스팅 + CloudFront + OAC
module "frontend" {
  source              = "../../modules/frontend"
  project_name        = var.project_name
  environment         = var.environment
  aliases             = ["rubao.store", "www.rubao.store"]
  acm_certificate_arn = aws_acm_certificate_validation.cloudfront.certificate_arn
  web_acl_id          = module.waf.web_acl_arn
}
 