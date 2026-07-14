terraform {
  backend "s3" {
    bucket         = "soundcloud-tfstate-201243087060" # <- 계정ID 붙여서 전역 유일하게
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-2"
    use_lockfile   = true
    encrypt        = true
  }
}
