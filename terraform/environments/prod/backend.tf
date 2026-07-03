# [Backend] State 원격 저장 + 잠금 - 버킷/테이블은 최초 1회 수동 생성
# aws s3 mb s3://soundcloud-tfstate-<계정ID>
# aws dynamodb create-table --table-name soundcloud-tflock \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST
terraform {
  backend "s3" {
    bucket         = "soundcloud-tfstate-Project_sc" # <- 계정ID 붙여서 전역 유일하게
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-2"
    dynamodb_table = "soundcloud-tflock"
    encrypt        = true
  }
}
