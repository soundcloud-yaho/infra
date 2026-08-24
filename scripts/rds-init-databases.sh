#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="${SCRIPT_DIR}/.."
TF_DIR="${INFRA_DIR}/terraform/environments/prod"
AWS_REGION="${AWS_REGION:-ap-northeast-2}"
JOB_NAME="rds-init-databases-$(date +%s)"

for COMMAND_NAME in terraform aws kubectl jq; do
  if ! command -v "${COMMAND_NAME}" >/dev/null 2>&1; then
    echo "[ FAIL ] ${COMMAND_NAME} 명령어가 필요합니다."
    exit 1
  fi
done

DATABASE_HOST=$(terraform -chdir="${TF_DIR}" output -raw database_host)
SECRET_ARN=$(terraform -chdir="${TF_DIR}" output -raw database_master_user_secret_arn)

if [ -z "${DATABASE_HOST}" ] || [ -z "${SECRET_ARN}" ]; then
  echo "[ FAIL ] RDS Terraform output을 확인할 수 없습니다."
  exit 1
fi

DB_USER=$(
  aws secretsmanager get-secret-value \
    --region "${AWS_REGION}" \
    --secret-id "${SECRET_ARN}" \
    --query SecretString \
    --output text |
  jq -er '.username'
)

if ! kubectl get namespace app >/dev/null 2>&1; then
  echo "[ FAIL ] app Namespace가 없습니다. create_secrets.sh를 먼저 실행하세요."
  exit 1
fi

if ! kubectl get secret rds-db-secret --namespace=app >/dev/null 2>&1; then
  echo "[ FAIL ] app/rds-db-secret이 없습니다. create_secrets.sh를 먼저 실행하세요."
  exit 1
fi

echo "[ INFO ] RDS 논리 데이터베이스 초기화 Job을 생성합니다: ${JOB_NAME}"

kubectl apply -f - <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
  namespace: app
spec:
  ttlSecondsAfterFinished: 300
  backoffLimit: 1
  template:
    spec:
      restartPolicy: Never
      nodeSelector:
        role: worker
      containers:
        - name: init-databases
          image: postgres:16
          env:
            - name: PGHOST
              value: "${DATABASE_HOST}"
            - name: PGPORT
              value: "5432"
            - name: PGUSER
              value: "${DB_USER}"
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: rds-db-secret
                  key: DB_PASSWORD
            - name: PGDATABASE
              value: "postgres"
            - name: PGSSLMODE
              value: "require"
          command: ["/bin/bash", "-ec"]
          args:
            - |
              for database_name in worldcup member comment prediction; do
                if psql -tAc "SELECT 1 FROM pg_database WHERE datname = '\${database_name}'" | grep -q 1; then
                  echo "[ SKIP ] \${database_name} 데이터베이스가 이미 존재합니다."
                else
                  psql -v ON_ERROR_STOP=1 -c "CREATE DATABASE \"\${database_name}\""
                  echo "[ OK ] \${database_name} 데이터베이스 생성 완료"
                fi
              done
YAML

if ! kubectl wait \
  --for=condition=complete \
  --timeout=300s \
  "job/${JOB_NAME}" \
  --namespace=app; then
  kubectl logs "job/${JOB_NAME}" --namespace=app || true
  echo "[ FAIL ] RDS 논리 데이터베이스 초기화에 실패했습니다."
  exit 1
fi

kubectl logs "job/${JOB_NAME}" --namespace=app
echo "[ OK ] RDS 논리 데이터베이스 초기화 완료"
