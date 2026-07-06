# [ECR] 이미지 저장소 2개 (backend / ai) + 수명주기 정책
resource "aws_ecr_repository" "this" {
  for_each = toset(var.ecr_repository_names)
  name     = "${var.project_name}-${var.environment}/${each.value}"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
}

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
