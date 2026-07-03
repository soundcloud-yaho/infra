# [ECR 모듈] 컨테이너 이미지 저장소 구성
# - backend, ai 서비스 이미지를 저장하기 위한 ECR Repository 생성
# - 이미지 푸시 시 취약점 스캔 활성화

resource "aws_ecr_repository" "this" {
  for_each = toset(var.repository_names)

  name                 = "${var.project_name}-${var.environment}-${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${each.value}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}