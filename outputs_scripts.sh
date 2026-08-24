#!/usr/bin/env bash
# [스크립트] Terraform output → K8s YAML 자동 반영
# 사용법: cd /infra && ./outputs_scripts.sh

# 실행 중 오류 및 미정의 변수 사용 시 스크립트 중단
set -euo pipefail

# 디렉토리설정
TF_DIR="terraform/environments/prod"
K8S_DIR="k8s"
DB_CONFIG_FILES=(
  "${K8S_DIR}/manifests/backend/config.yaml"
  "${K8S_DIR}/manifests/member/config.yaml"
  "${K8S_DIR}/manifests/comment/config.yaml"
  "${K8S_DIR}/manifests/prediction/config.yaml"
)

# ── 1. Terraform output 읽기 ──────────────────────────
echo "[1/3] Terraform output 읽는 중..."
API_CERT_ARN=$(terraform -chdir="${TF_DIR}" output -raw api_certificate_arn 2>/dev/null || true)
DATABASE_HOST=$(terraform -chdir="${TF_DIR}" output -raw database_host 2>/dev/null || true)

# 필수 값 누락 시 중단
if [ -z "${API_CERT_ARN}" ] || [ -z "${DATABASE_HOST}" ]; then
  echo "[ FAIL ] 필수 값이 없습니다. terraform apply가 완료됐는지 확인하세요."
  exit 1
fi

echo "[ OK ] Terraform output 읽기 완료"

# ── 2. Terraform output 반영 ──────────────────────────
echo "[2/3] Terraform output 반영 중..."

sed -i -E \
  "s|^([[:space:]]*alb.ingress.kubernetes.io/certificate-arn:).*$|\1 ${API_CERT_ARN}|" \
  "${K8S_DIR}/manifests/backend/ingress.yaml"

for CONFIG_FILE in "${DB_CONFIG_FILES[@]}"; do
  sed -i -E \
    "s|^([[:space:]]*DB_HOST:).*$|\1 \"${DATABASE_HOST}\"|" \
    "${CONFIG_FILE}"
done

echo "[ OK ] Terraform output 반영 완료"

# ── 3. 결과 확인 ──────────────────────────────────────
echo "[3/3] 치환 결과 확인중..."

REMAINING=$(grep -r "CHANGEME" \
  "${K8S_DIR}/manifests/backend/ingress.yaml" \
  "${DB_CONFIG_FILES[@]}" 2>/dev/null || true)

if [ -n "${REMAINING}" ]; then
  echo "[ FAIL ]  미치환 CHANGEME 잔존:"
  echo "${REMAINING}"
  exit 1
fi

for CONFIG_FILE in "${DB_CONFIG_FILES[@]}"; do
  if ! grep -Fq "DB_HOST: \"${DATABASE_HOST}\"" "${CONFIG_FILE}"; then
    echo "[ FAIL ] ${CONFIG_FILE}에서 database_host 반영 결과를 확인할 수 없습니다."
    exit 1
  fi
done

if ! grep -Fq "alb.ingress.kubernetes.io/certificate-arn: ${API_CERT_ARN}" \
  "${K8S_DIR}/manifests/backend/ingress.yaml"; then
  echo "[ FAIL ] api_certificate_arn 반영 결과를 확인할 수 없습니다."
  exit 1
fi

echo "[ OK ] 모든 Terraform output 반영 완료!"
