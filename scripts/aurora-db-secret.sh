#!/usr/bin/env bash

set -euo pipefail

# 스크립트 위치를 기준으로 prod Terraform 디렉터리 설정
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${SCRIPT_DIR}/../terraform/environments/prod"

AWS_REGION="${AWS_REGION:-ap-northeast-2}"

SECRET_ARN="$(
  terraform -chdir="${TERRAFORM_DIR}" \
    output -raw master_user_secret_arn
)"

DB_PASSWORD="$(
  aws secretsmanager get-secret-value \
    --region "${AWS_REGION}" \
    --secret-id "${SECRET_ARN}" \
    --query SecretString \
    --output text |
  jq -er '.password'
)"

kubectl create secret generic aurora-db-secret \
  --namespace=app \
  --from-literal="DB_PASSWORD=${DB_PASSWORD}" \
  --dry-run=client \
  -o yaml |
kubectl apply -f -

unset DB_PASSWORD

echo "aurora-db-secret 적용 완료"