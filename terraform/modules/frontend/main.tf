# [Frontend] S3(정적 호스팅) + CloudFront(엣지 캐시) + OAC
# 버킷은 퍼블릭 차단, CloudFront만 OAC로 읽기 허용 -> S3 URL 직접 접근 시 403이 정상

resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.name}-frontend-${data.aws_caller_identity.current.account_id}" # 전역 유일해야 해서 계정ID 접미사
  force_destroy = true # 졸업 프로젝트용 - destroy 시 파일 있어도 삭제 허용
}

data "aws_caller_identity" "current" {}

# ---------- 퍼블릭 접근 완전 차단 ----------
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------- CloudFront 배포 ----------
resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "${var.name}-frontend-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  default_root_object = "index.html"
  price_class         = "PriceClass_200" # 한국/아시아 리전 포함, 전세계 최고가 등급 제외로 비용 절감

  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods          = ["GET", "HEAD"]
    cache_policy_id         = "658327ea-f89d-4fab-a63d-7e88639e58f6" # AWS 관리형 CachingOptimized
  }

  # CSR 앱이라 404/403도 index.html로 돌려서 클라이언트 라우팅이 처리하게 함
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true # 커스텀 도메인 쓰면 acm_certificate_arn으로 교체
  }
}

# ---------- 버킷 정책: CloudFront(OAC)만 읽기 허용 ----------
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCloudFrontOAC"
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
        }
      }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}

# ---------- CI가 s3 sync / cloudfront invalidation을 실행할 IAM 유저 (또는 OIDC 연동 권장) ----------
resource "aws_iam_policy" "frontend_deploy" {
  name = "${var.name}-frontend-deploy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Sync"
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*"
        ]
      },
      {
        Sid      = "Invalidate"
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = aws_cloudfront_distribution.frontend.arn
      }
    ]
  })
}
