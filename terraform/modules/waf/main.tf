# CloudFront 앞단에 연결할 AWS WAF Web ACL 구성
# AWS Managed Rule을 사용하여 일반적인 웹 공격, 악성 입력값, SQL Injection 요청을 차단
# WAF 로그는 S3 Bucket에 저장하여 이후 차단/허용 요청 분석에 활용

# 현재 AWS 계정 정보 조회
data "aws_caller_identity" "current" {}

# WAF 로그를 저장할 S3 Bucket
resource "aws_s3_bucket" "waf_logs" {
  bucket = "aws-waf-logs-${var.project_name}-${var.environment}-cloudfront-${data.aws_caller_identity.current.account_id}"
}

# S3 Bucket 외부 접근 차단
resource "aws_s3_bucket_public_access_block" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket 소유권을 Bucket Owner로 고정
resource "aws_s3_bucket_ownership_controls" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# 저장되는 로그 암호화
resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 로그 버전 관리
resource "aws_s3_bucket_versioning" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 오래된 로그 자동 삭제
resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    id     = "expire-waf-logs"
    status = "Enabled"

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# CloudFront에 연결할 Web ACL
resource "aws_wafv2_web_acl" "cloudfront" {
  name        = "${var.project_name}-${var.environment}-cloudfront-waf"
  description = "AWS WAF Web ACL for CloudFront"
  scope       = "CLOUDFRONT"

  # 기본적으로 요청을 허용
  default_action {
    allow {}
  }

  # 과도한 요청을 보내는 IP 차단
  rule {
    name     = "RateBasedRule"
    priority = 0

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateBasedRule"
      sampled_requests_enabled   = true
    }
  }

  # 악성 IP 평판 기반 차단
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesAmazonIpReputationList"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  # 일반적인 웹 공격 차단
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # 악성 입력값 차단
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # SQL Injection 공격 차단
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesSQLiRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # WAF 메트릭 수집 설정
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-${var.environment}-cloudfront-waf"
    sampled_requests_enabled   = true
  }
}

# WAF 로그를 S3로 저장
resource "aws_wafv2_web_acl_logging_configuration" "cloudfront" {
  resource_arn = aws_wafv2_web_acl.cloudfront.arn

  log_destination_configs = [
    aws_s3_bucket.waf_logs.arn
  ]

  # 민감한 요청 헤더는 마스킹
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }

  # S3 보안 설정 완료 후 Logging 구성
  depends_on = [
    aws_s3_bucket_public_access_block.waf_logs,
    aws_s3_bucket_ownership_controls.waf_logs,
    aws_s3_bucket_server_side_encryption_configuration.waf_logs
  ]
}