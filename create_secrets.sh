#!/bin/bash
# [스크립트] K8s Secret 생성 자동화
# Aurora 비밀번호 → AWS Secrets Manager 자동 조회
# secrets.md 값 → secrets.tfvars 작성필요.
# 사용법: cd /infra && ./create_secrets.sh

set -e

TF_DIR="terraform/environments/prod"
SECRETS_FILE="terraform/environments/prod/secrets.tfvars"

echo "======================================"
echo " K8s Secret 생성 스크립트"
echo "======================================"
echo ""

# ── 1. secrets.tfvars 존재 확인 ───────────────────────
echo "[1/4] secrets.tfvars 확인 중..."

if [ ! -f "${SECRETS_FILE}" ]; then
  echo "[ FAIL ] secrets.tfvars 파일이 없습니다."
  echo "         아래 형식으로 생성 후 다시 실행하세요:"
  echo ""
  echo "  tailscale_auth_key     = \"tskey-auth-xxxx\""
  echo "  slack_webhook_url      = \"https://hooks.slack.com/...\""
  echo "  grafana_admin_password = \"your-password\""
  exit 1
fi

# secrets.tfvars에서 값 읽기 (따옴표 제거)
TAILSCALE_AUTH_KEY=$(grep tailscale_auth_key "${SECRETS_FILE}" | \
  sed 's/.*= *"//' | sed 's/".*//')
SLACK_WEBHOOK_URL=$(grep slack_webhook_url "${SECRETS_FILE}" | \
  sed 's/.*= *"//' | sed 's/".*//')
GRAFANA_ADMIN_PASSWORD=$(grep grafana_admin_password "${SECRETS_FILE}" | \
  sed 's/.*= *"//' | sed 's/".*//')

# 값 검증
if [ -z "${TAILSCALE_AUTH_KEY}" ] || \
   [ -z "${SLACK_WEBHOOK_URL}" ] || \
   [ -z "${GRAFANA_ADMIN_PASSWORD}" ]; then
  echo "[ FAIL ] secrets.tfvars에 누락된 값이 있습니다."
  exit 1
fi

echo "[ OK ] secrets.tfvars 읽기 완료"

# ── 2. Aurora 비밀번호 자동 조회 ──────────────────────
echo "[2/4] Aurora 비밀번호 AWS Secrets Manager에서 조회 중..."
cd "${TF_DIR}"

SECRET_ARN=$(terraform output -raw aurora_master_user_secret_arn 2>/dev/null || echo "")
cd -

if [ -z "${SECRET_ARN}" ]; then
  echo "[ FAIL ] aurora_master_user_secret_arn 조회 실패"
  exit 1
fi

DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "${SECRET_ARN}" \
  --query SecretString \
  --output text | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")

if [ -z "${DB_PASSWORD}" ]; then
  echo "[ FAIL ] Aurora 비밀번호 조회 실패"
  exit 1
fi

echo "[ OK ] Aurora 비밀번호 자동 조회 완료"

# ── 3. Secret 생성 ────────────────────────────────────
echo ""
echo "[3/4] K8s Secret 생성 중..."

# 네임스페이스 생성 (없으면 자동 생성)
for NS in app tailscale ai monitoring; do
  kubectl get namespace "${NS}" > /dev/null 2>&1 || \
    kubectl create namespace "${NS}"
done

# aurora-db-secret (app)
kubectl create secret generic aurora-db-secret \
  --from-literal=DB_PASSWORD="${DB_PASSWORD}" \
  --namespace=app \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[ OK ] aurora-db-secret (app)"

# tailscale-auth (tailscale)
kubectl create secret generic tailscale-auth \
  --from-literal=TS_AUTHKEY="${TAILSCALE_AUTH_KEY}" \
  --namespace=tailscale \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[ OK ] tailscale-auth (tailscale)"

# slack-webhook (ai)
kubectl create secret generic slack-webhook \
  --from-literal=SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL}" \
  --namespace=ai \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[ OK ] slack-webhook (ai)"

# grafana-admin-secret (monitoring)
kubectl create secret generic grafana-admin-secret \
  --from-literal=admin-user='admin' \
  --from-literal=admin-password="${GRAFANA_ADMIN_PASSWORD}" \
  --namespace=monitoring \
  --dry-run=client -o yaml | kubectl apply -f -
echo "[ OK ] grafana-admin-secret (monitoring)"

# ── 4. 결과 확인 ──────────────────────────────────────
echo ""
echo "[4/4] 생성된 Secret 확인..."
echo ""

for NS_SECRET in \
  "app/aurora-db-secret" \
  "tailscale/tailscale-auth" \
  "ai/slack-webhook" \
  "monitoring/grafana-admin-secret"; do
  NS="${NS_SECRET%%/*}"
  SECRET="${NS_SECRET##*/}"
  kubectl get secret "${SECRET}" -n "${NS}" \
    --no-headers 2>/dev/null && echo "[ OK ]  ${NS}/${SECRET}" || \
    echo "[ FAIL ] ${NS}/${SECRET} 생성 실패"
done

echo ""
echo "======================================"
echo " 모든 Secret 생성 완료!"
echo "======================================"
