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

---

## 자동 생성되는 것 (참고, 수동 생성 불필요)

- tailscale-state (namespace: tailscale) — tailscale 파드가 TS_KUBE_SECRET으로 자동 생성. rbac.yaml의 secret 권한으로 가능.