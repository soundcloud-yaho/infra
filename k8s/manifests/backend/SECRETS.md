# 수동 생성 Secret 목록

이 값들은 비밀이라 git에 올리지 않는다. root-app apply 전에 아래 명령어로 클러스터에 직접 생성
실제 값은 이 문서에 적지 않는다 — 명령어 형태만 기록

## aurora-db-secret (namespace: app)
DB 비밀번호. backend Deployment + sync-matches CronJob이 사용.

kubectl create secret generic aurora-db-secret \
  --namespace=app \
  --from-literal=DB_PASSWORD='<실제 비번으로 교체>'

## tailscale-auth (namespace: tailscale)
Tailscale 인증키. subnet router 파드가 tailnet 로그인에 사용.

kubectl create secret generic tailscale-auth \
  --namespace=tailscale \
  --from-literal=TS_AUTHKEY='<실제 키로 교체>'

## slack-webhook (namespace: ai)
Quantile Regression 노드 사이징 권고 결과 전송용.

kubectl create secret generic slack-webhook \
  --namespace=ai \
  --from-literal=SLACK_WEBHOOK_URL='<실제 URL로 교체>'

## grafana adein 
kubectl create secret generic grafana-admin-secret \
  --namespace=monitoring \
  --from-literal=admin-user='admin' \
  --from-literal=admin-password='<실제 비번>'
---

## 자동 생성되는 것 (참고, 수동 생성 불필요)

- tailscale-state (namespace: tailscale) — tailscale 파드가 TS_KUBE_SECRET으로 자동 생성. rbac.yaml의 secret 권한으로 가능.

---------------------------
scripts/aurora-db-secret.sh
---------------------------
### 전제 조건

- `terraform`, `aws`, `kubectl`, `jq` 설치
- AWS CLI 인증 완료
- EKS와 Aurora가 Terraform으로 생성된 상태
- Terraform state에 `master_user_secret_arn` output 존재
- 실행 IAM 주체에 다음 권한 필요
  - `eks:DescribeCluster`
  - `secretsmanager:GetSecretValue`
  - 필요 시 `kms:Decrypt`
- EKS 접근 권한 및 `app` namespace의 Secret 생성·수정 RBAC 권한 필요
- `app` namespace가 미리 생성되어 있어야 함

### 실행
# 터미널 루트 이동
cd ~/project03/infra

# 최초 1회 실행 권한 부여
chmod +x scripts/aurora-db-secret.sh

# 스크립트 실행
./scripts/aurora-db-secret.sh

# 정상 작동 확인 // 데이터가 1이면 DB_PASSWARD 키가 생성된 것
kubectl get secret aurora-db-secret -n app
# NAME               TYPE     DATA
# aurora-db-secret   Opaque   1
---------------------------
# secret값이 변경된 경우에 재시작 // pod가 올라올 때까지 최대 180초 대기 
kubectl rollout restart deployment/backend -n app
kubectl rollout status \
  deployment/backend \
  -n app \
  --timeout=180s

# deployment "backend" successfully rolled out
# or
# error: timed out waiting for the condition
