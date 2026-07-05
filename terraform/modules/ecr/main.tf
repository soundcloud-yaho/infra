# [ECR] 이미지 저장소 2개 (backend / ai) + 수명주기 정책
resource "aws_ecr_repository" "this" {
  for_each = toset(var.ecr_repository_names)
  name     = "${var.project_name}-${var.environment}/${each.value}"

  image_scanning_configuration {
    scan_on_push = true # 푸시 때마다 취약점 스캔
  }

  force_delete = true # 졸업 프로젝트용 - destroy 때 이미지 있어도 삭제 (AIDAS S3 versioning 사태 재발 방지)
}

# 최근 10개만 보관 - 안 지우면 이미지가 쌓여서 스토리지 요금 나감
resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = aws_ecr_repository.this
  repository = each.value.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
