terraform {
  backend "s3" {
    bucket         = "soundcloud-tfstate-201243087060" # <- 계정ID 붙여서 전역 유일하게
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "soundcloud-tflock"
    encrypt        = true
  }
}
