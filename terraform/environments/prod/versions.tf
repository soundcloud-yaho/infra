# [Versions] terraform/aws provider 버전 고정 — 팀원 간 버전 불일치 방지

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.53"
    }
  }
}