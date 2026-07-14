#!/usr/bin/env bash

set -Eeuo pipefail

AWS_REGION="${AWS_REGION:-ap-northeast-2}"
EKS_CLUSTER_NAME="${EKS_CLUSTER_NAME:-soundcloud-prod-eks}"
NAMESPACE="${NAMESPACE:-app}"
SECRET_NAME="${SECRET_NAME:-aurora-db-secret}"

# 이 스크립트가 infra/scripts/ 안에 있다는 기준
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INFRA_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

# 필요하면 실행할 때 TERRAFORM_DIR로 덮어쓸 수 있음
TERRAFORM_DIR="${
  TERRAFORM_DIR:-${INFRA_ROOT}/terraform/environments/prod
}"

log() {
  echo "[INFO] $*"
}

fail() {
  echo "[ERROR] $*" >&2
  exit 1
}

cleanup() {
  unset DB_PASSWORD 2>/dev/null || true
}

trap cleanup EXIT

# ------------------------------------------------------------
# 1. 필수 명령어 확인
# ------------------------------------------------------------

required_commands=(
  terraform
  aws
  kubectl
  jq
)

for command_name in "${required_commands[@]}"; do
  command -v "${command_name}" >/dev/null 2>&1 ||
    fail "${command_name}이 설치되어 있지 않습니다."
done

# ------------------------------------------------------------
# 2. Terraform 디렉터리 확인
# ------------------------------------------------------------

[[ -d "${TERRAFORM_DIR}" ]] ||
  fail "Terraform 디렉터리가 없습니다: ${TERRAFORM_DIR}"

log "Terraform 디렉터리: ${TERRAFORM_DIR}"

# ------------------------------------------------------------
# 3. AWS 인증 확인
# ------------------------------------------------------------

log "AWS 인증 상태를 확인합니다."

aws sts get-caller-identity \
  --region "${AWS_REGION}" \
  >/dev/null ||
  fail "AWS 인증 정보를 확인할 수 없습니다."

# ------------------------------------------------------------
# 4. EKS kubeconfig 생성 또는 갱신
# 반복 실행해도 같은 클러스터 설정으로 갱신됨
# ------------------------------------------------------------

log "EKS kubeconfig를 설정합니다: ${EKS_CLUSTER_NAME}"

aws eks update-kubeconfig \
  --region "${AWS_REGION}" \
  --name "${EKS_CLUSTER_NAME}" \
  >/dev/null ||
  fail "EKS kubeconfig 설정에 실패했습니다."

kubectl cluster-info >/dev/null ||
  fail "EKS 클러스터에 연결할 수 없습니다."

# ------------------------------------------------------------
# 5. Namespace 및 Kubernetes 권한 확인
# ------------------------------------------------------------

kubectl get namespace "${NAMESPACE}" >/dev/null ||
  fail "${NAMESPACE} Namespace가 없습니다."

for verb in get create patch update; do
  kubectl auth can-i "${verb}" secrets \
    --namespace="${NAMESPACE}" |
    grep -qx "yes" ||
    fail "${NAMESPACE} Namespace에서 Secret ${verb} 권한이 없습니다."
done

# ------------------------------------------------------------
# 6. Terraform output에서 Aurora Secret ARN 조회
# ------------------------------------------------------------

log "Aurora Secret ARN을 조회합니다."

if ! SECRET_ARN="$(
  terraform -chdir="${TERRAFORM_DIR}" \
    output -raw master_user_secret_arn
)"; then
  fail "master_user_secret_arn을 조회하지 못했습니다. Terraform init 및 state를 확인하세요."
fi

[[ -n "${SECRET_ARN}" ]] ||
  fail "master_user_secret_arn 값이 비어 있습니다."

# ------------------------------------------------------------
# 7. AWS Secrets Manager에서 DB 비밀번호 조회
# ------------------------------------------------------------

log "AWS Secrets Manager에서 Aurora 비밀번호를 조회합니다."

DB_PASSWORD="$(
  aws secretsmanager get-secret-value \
    --region "${AWS_REGION}" \
    --secret-id "${SECRET_ARN}" \
    --query SecretString \
    --output text |
  jq -er '
    .password
    | select(type == "string" and length > 0)
  '
)" ||
  fail "Aurora DB 비밀번호를 조회하지 못했습니다."

# ------------------------------------------------------------
# 8. Kubernetes Secret 생성 또는 갱신
#
# Secret 없음  → 생성
# Secret 있음  → 변경사항 갱신
# 같은 값      → 그대로 유지
# ------------------------------------------------------------

log "${SECRET_NAME}을 적용합니다."

kubectl create secret generic "${SECRET_NAME}" \
  --namespace="${NAMESPACE}" \
  --from-literal="DB_PASSWORD=${DB_PASSWORD}" \
  --dry-run=client \
  -o yaml |
kubectl apply -f -

unset DB_PASSWORD

# ------------------------------------------------------------
# 9. 적용 결과 확인
# 비밀번호 값은 출력하지 않음
# ------------------------------------------------------------

kubectl get secret "${SECRET_NAME}" \
  --namespace="${NAMESPACE}"

log "${SECRET_NAME} 적용 완료"