# worldcup-infra

Sound_Cloud 팀의 인프라 레포. **FIFA 월드컵 2026 서비스**를 대상으로 FinOps 기반 멀티 리전 EKS 플랫폼을 구현한다.

클러스터 밖(Terraform)과 클러스터 안(K8s 매니페스트, ArgoCD 감시 대상)을 한 레포에서 관리하되 폴더로 완전히 분리한다.

---

## 전체 아키텍처

```
사용자
  │
  ├─ Route 53 (정적 도메인) → CloudFront → S3 (HTML/JS)
  │
  └─ Route 53 (API 도메인) → ALB (Public subnet)
                                  └─ FastAPI Pod (Private subnet, target-type: ip)
                                        ├─ SELECT → Aurora Reader (DB subnet)
                                        └─ (동기화 CronJob) UPSERT → Aurora Writer

외부 데이터:
  동기화 CronJob → NAT Gateway → football-data.org (1시간 폴링)

AI 예측 → 스케일링 루프:
  Prometheus (지표 수집)
    → NeuralProphet 추론 CronJob (5분 주기)
      → Pushgateway
        → KEDA (예측 메트릭 선제 + 실측 CPU/RPS 보험, 이중 트리거)
          → replica 증감
            → Pod Pending 발생 시
              → Karpenter → Spot Worker 노드 프로비저닝
```

---

## 노드 그룹 구성

EKS 워커 노드를 역할별로 3개 그룹으로 분리한다. 각 그룹은 Terraform 관리형 노드그룹으로 상시 유지되며, Spot 버스트만 Karpenter가 동적으로 관리한다.

| 노드그룹 | 타입 | 수량 | 역할 |
|---|---|---|---|
| System | ON_DEMAND | 2 | Karpenter, KEDA, ArgoCD, LB Controller, Prometheus/Grafana/Kubecost, Tailscale |
| AI | ON_DEMAND | 1 | NeuralProphet, "Segmented Quantile, Isolation Forest, Bedrock 리포트 CronJob |
| Worker | ON_DEMAND | 1 | FastAPI 베이스라인 (항상 최소 1개 유지, 콜드스타트 방지) |
| Spot Worker | Spot | 0~N | 경기 시간대 버스트 — Karpenter가 초 단위로 구매/반납 |

**System 노드 2개**: Karpenter, KEDA 등 핵심 컨트롤러가 replica=2로 동작해 Leader Election 방식으로 HA를 구성한다. 노드 1개 장애 시 즉시 다른 노드에서 Leader 승계, 공백 없음.

**AI 노드 ON_DEMAND 고정**: 학습 도중 Spot 회수로 연산이 유실되는 것을 방지한다. taint(`dedicated=ai:NoSchedule`)로 일반 서비스 Pod의 진입을 차단한다.

**Worker ON_DEMAND 베이스라인**: FastAPI가 항상 최소 1개 떠있어야 경기 시작 직전 선제 스케일링이 의미 있다. 베이스라인 없으면 첫 요청 시 노드 생성 대기(1~3분) 후 응답하는 콜드스타트 문제 발생.

---

## Terraform 모듈 구성

```
terraform/
  modules/
    network/     VPC, 3계층 서브넷(Public/Private/DB), NAT GW, ELB 태그, karpenter.sh/discovery 태그
    eks/         EKS 클러스터, 관리형 노드그룹 3개(System/AI/Worker), OIDC 프로바이더
    karpenter/   컨트롤러 IRSA Role, 노드 IAM Role, SQS 인터럽션 큐, EventBridge 규칙 4종
    security/    SG 체인(ALB→EKS→Aurora), LB Controller IRSA, KMS(Aurora 암호화)
    database/    Aurora PostgreSQL(Writer+Reader), 파라미터 그룹(KST 타임존)
    ecr/         이미지 저장소 2개 — backend, ai
    frontend/    S3(정적 호스팅), CloudFront, OAC, CI 배포 IAM 정책
  environments/
    prod/        모듈 호출부, 변수, outputs
```

### 모듈 간 의존 관계

```
network → eks → karpenter
              └→ security → database
network → security
eks     → security
ecr     (독립)
frontend (독립)
```

### outputs.tf — 두 트랙을 잇는 접점

`environments/prod/outputs.tf`의 값을 `k8s/values/*.yaml`에 수동으로 복사한다.

| output 키 | 용도 |
|---|---|
| `eks_cluster_name` | karpenter-values.yaml |
| `karpenter_controller_role_arn` | karpenter-values.yaml serviceAccount annotation |
| `karpenter_interruption_queue` | karpenter-values.yaml settings |
| `karpenter_node_role_name` | ec2nodeclass.yaml spec.role |
| `lb_controller_role_arn` | aws-lb-controller-values.yaml |
| `aurora_writer_endpoint` | K8s Secret (동기화 CronJob용) |
| `aurora_reader_endpoint` | K8s Secret (FastAPI용) |
| `aurora_master_user_secret_arn` | Secrets Manager 자동 관리 |
| `ecr_repository_urls` | CI 워크플로우, deployment.yaml |
| `frontend_bucket_name` | frontend CI s3 sync |
| `frontend_cloudfront_distribution_id` | frontend CI invalidation |

**apply는 로컬 수동으로만.** CI(`terraform-plan.yaml`)는 PR에 plan 결과만 코멘트하고 apply하지 않는다.

---

## K8s 구성 (ArgoCD 감시 대상)

```
k8s/
  bootstrap/
    root-app.yaml          App of Apps 루트 — 수동 apply 1회, 이후 전부 자동
  apps/
    karpenter.yaml
    aws-lb-controller.yaml
    monitoring.yaml        kube-prometheus-stack (Prometheus/Grafana/Alertmanager/Node Exporter)
    kubecost.yaml
    keda.yaml
    argocd.yaml
    backend.yaml
    ai-pipeline.yaml
  values/
    karpenter-values.yaml         terraform output 값 포함
    aws-lb-controller-values.yaml terraform output 값 포함
    kube-prometheus-stack-values.yaml
    kubecost-values.yaml
    keda-values.yaml
  manifests/
    base/
      namespaces.yaml      monitoring / app / ai / kube-system
    karpenter/
      ec2nodeclass.yaml    AMI, 서브넷/SG discovery 태그 셀렉터
      nodepool-spot-worker.yaml  Spot 버스트 NodePool (c5/c6i/m5/m6i, 4~6종 다양화)
    backend/
      deployment.yaml      FastAPI (nodeSelector: role: worker)
      service.yaml
      ingress.yaml         ALB Ingress (target-type: ip)
      pdb.yaml             Spot 회수 시 동시 종료 제한
      keda-scaledobject.yaml  이중 트리거 ScaledObject
    ai/
      np-train-cronjob.yaml     NeuralProphet 학습 (일 1회, toleration: dedicated=ai)
      np-predict-cronjob.yaml   NeuralProphet 추론 (5분, toleration: dedicated=ai)
      qr-report-cronjob.yaml    "Segmented Quantile 권고 리포트 (주 1회)
      bedrock-report-cronjob.yaml  Kubecost → Bedrock → Slack (주 1회)
      sync-cronjob.yaml         football-data.org 동기화 (1시간)
```

### 네임스페이스 구성

| 네임스페이스 | 파드 |
|---|---|
| `kube-system` | Karpenter, LB Controller, CoreDNS, kube-proxy, VPC CNI |
| `monitoring` | Prometheus, Grafana, Alertmanager, Pushgateway, Kubecost, Node Exporter |
| `argocd` | ArgoCD 전체 |
| `keda` | KEDA Operator |
| `app` | FastAPI, 동기화 CronJob |
| `ai` | AI CronJob 전체 |

### 배포 원리

```
코드 변경:
  worldcup-backend / worldcup-ai push
    → CI 이미지 빌드 → ECR 저장 (배포 아님)

실제 배포:
  k8s/manifests/{backend,ai}/*.yaml 이미지 태그 수정 후 커밋
    → ArgoCD 감지 → 클러스터 반영
    → 롤백: git revert 한 방
```

### Karpenter Spot 중단 대응

```
AWS Spot 회수 2분 전 통보
  → EventBridge → SQS 인터럽션 큐 → Karpenter 수신
    → cordon (새 Pod 차단)
    → 대체 노드 먼저 구매
    → 기존 노드 drain
    → 서비스 무중단 유지
```

인스턴스 타입 4~6종 다양화로 특정 Spot 풀 회수 시 다른 풀로 즉시 대체한다.

---

## 보안 설계

### SG 최소 권한 체인

```
인터넷 → ALB SG (80/443)
           → EKS Node SG (app_port만)
             → Aurora SG (5432만)
```

각 SG가 이전 SG를 소스로 참조 — IP 변경에도 자동 추적.

### IRSA (IAM Role for Service Accounts)

Pod가 AWS API를 호출할 수 있게 ServiceAccount 단위로 IAM 권한 부여. OIDC 프로바이더가 EKS Pod 토큰을 AWS IAM이 신뢰하게 만드는 다리 역할.

| 컴포넌트 | 권한 |
|---|---|
| Karpenter | EC2 생성/삭제, SQS 수신 |
| LB Controller | ALB/타겟그룹 자동 관리 |

### KMS

Aurora 저장 데이터를 고객 관리형 KMS 키로 암호화. key rotation 활성화(1년 주기 자동 교체).

---

## 사전 준비 (Bootstrap)

자세한 순서는 `docs/BOOTSTRAP.md` 참고.

```bash
# 1. State 백엔드 수동 생성 (최초 1회)
aws s3 mb s3://soundcloud-tfstate-{계정ID} --region ap-northeast-2
aws dynamodb create-table \
  --table-name soundcloud-tflock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

# 2. LB Controller 정책 JSON 받기 (최초 1회)
curl -o terraform/modules/security/lb_controller_policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json

# 3. DB 비밀번호 환경변수 주입 (tfvars에 평문 저장 금지)
export TF_VAR_db_master_password='비밀번호'

# 4. Terraform 적용
cd terraform/environments/prod
terraform init
terraform apply

# 5. output 값을 k8s/values/*.yaml에 복사
terraform output

# 6. ArgoCD 수동 설치 (1회)
helm install argocd argo/argo-cd -n argocd --create-namespace

# 7. App of Apps 등록 → 이후 전 컴포넌트 자동 배포
kubectl apply -f k8s/bootstrap/root-app.yaml
```

---

## 브랜치 규칙

- `maister` 직접 push 금지
- PR 리뷰 1명 필수