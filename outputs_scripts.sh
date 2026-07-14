#!/bin/bash
# [스크립트] Terraform output → k8s YAML CHANGEME 자동 치환
# 사용법: cd /infra && ./outputs_scripts.sh

# 실행중 에러 발생 시 스크립트 중단
set -e

# 디렉토리설정
TF_DIR="terraform/environments/prod"
K8S_DIR="k8s"

# ── 1. Terraform output 읽기 ──────────────────────────
echo "[1/3] Terraform output 읽는 중..."
cd "${TF_DIR}"

API_CERT_ARN=$(terraform output -raw api_certificate_arn 2>/dev/null || echo "")
AURORA_WRITER=$(terraform output -raw aurora_writer_endpoint 2>/dev/null || echo "")
AURORA_READER=$(terraform output -raw aurora_reader_endpoint 2>/dev/null || echo "")

# 필수 값 누락 시 중단
if
   [ -z "${API_CERT_ARN}" ] || \
   [ -z "${AURORA_WRITER}" ] || \
   [ -z "${AURORA_READER}" ]; then
  echo "[ FAIL ] 필수 값이 없습니다. terraform apply가 완료됐는지 확인하세요."
  exit 1
fi

echo "[ OK ] Terraform output 읽기 완료"
cd -

# ── 2. CHANGEME 치환 ──────────────────────────────────
echo "[2/3] CHANGEME 치환 중..."

sed -i "s|CHANGEME_API_CERT_ARN|${API_CERT_ARN}|g" \
  "${K8S_DIR}/manifests/backend/ingress.yaml"

sed -i "s|CHANGEME_AURORA_WRITER_ENDPOINT|${AURORA_WRITER}|g" \
  "${K8S_DIR}/manifests/backend/config.yaml"

sed -i "s|CHANGEME_AURORA_READER_ENDPOINT|${AURORA_READER}|g" \
  "${K8S_DIR}/manifests/backend/config.yaml"

echo "[ OK ] 치환 완료"

# ── 3. 결과 확인 ──────────────────────────────────────
echo "[3/3] 치환 결과 확인중..."

REMAINING=$(grep -r "CHANGEME" \
  "${K8S_DIR}/manifests/backend/ingress.yaml" \
  "${K8S_DIR}/manifests/backend/config.yaml" 2>/dev/null || true)

if [ -n "${REMAINING}" ]; then
  echo "[ FAIL ]  미치환 CHANGEME 잔존:"
  echo "${REMAINING}"
else
  echo "[ OK ]모든 CHANGEME -> OUTPUT 치환 완료!"
fi