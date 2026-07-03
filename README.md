# worldcup-infra

Sound_Cloud 프로젝트의 인프라 레포. **클러스터 밖(Terraform)**과 **클러스터 안(K8s 매니페스트, ArgoCD 감시 대상)**을 한 레포에서 관리하되 폴더로 완전히 분리한다.


---

## 아키텍처 개요

```
사용자 → Route 53 ┬→ CloudFront → S3 (정적 프론트)
                   └→ ALB(Public subnet)
                         └→ FastAPI Pod(Private subnet, target-type: ip)
                               └→ Aurora Writer/Reader(DB subnet)

동기화 CronJob → NAT Gateway → football-data.org (1시간 폴링 → Aurora Writer UPSERT)

Prometheus → NeuralProphet 추론(5분) → Pushgateway → KEDA(이중 트리거) → replica 증감
                                                              ↓ (Pending 발생 시)
                                                        Karpenter → Spot 노드 프로비저닝
```

VPC는 3계층(Public / Private / DB subnet), EKS 워커는 **노드 그룹 3분리** 구조를 따른다.

| 노드 그룹 | 인스턴스 | 역할 |
|---|---|---|
| System | On-Demand | Karpenter, KEDA, ArgoCD, LB Controller, Prometheus/Grafana/Kubecost, Tailscale — 관제 컴포넌트 상주 |
| AI/MLOps | On-Demand | NeuralProphet, Quantile Regression, Isolation Forest CronJob — 학습 도중 Spot 회수로 작업 유실 방지 |
| Spot Worker | Spot (다중 인스턴스 타입) | FastAPI 서비스 Pod — 경기 시간대 버스트, Karpenter가 초 단위로 구매/반납 |

DR 전략은 **Warm Standby** (도쿄 리전에 최소 EKS + Aurora Global 상시, 장애 시 Route 53 failover + Karpenter 확장). 발표 전 2주만 가동.

---

## `terraform/` 모듈 구성

| 모듈 | 내용 |
|---|---|
| `network` | VPC, 3계층 서브넷, ELB 태그 2종(`kubernetes.io/role/elb`, `internal-elb`), `karpenter.sh/discovery` 태그, NAT Gateway |
| `eks` | EKS 클러스터, System 관리형 노드그룹, OIDC 프로바이더 (모든 IRSA의 뿌리) |
| `karpenter` | 컨트롤러 IRSA Role, 노드 IAM Role/Instance Profile, SQS 인터럽션 큐, EventBridge 규칙 4종(중단/리밸런스/상태변경/예약변경) |
| `database` | Aurora PostgreSQL (Writer + Reader), 파라미터 그룹(커넥션 수, KST 타임존) |
| `security` | SG 최소 권한 체인 `ALB → EKS → Aurora`, LB Controller IRSA Role, (확장) WAF |
| `ecr` | 이미지 저장소 2개 — `backend`, `ai` |

`environments/prod/outputs.tf`가 두 트랙(terraform ↔ k8s)을 잇는 유일한 접점이다. 여기서 나온 값(클러스터명, IRSA ARN들, SQS 큐명, ECR URL, Aurora 엔드포인트 2종)을 `k8s/values/*.yaml`에 수동으로 복사한다.

**apply는 로컬에서 수동으로만.** CI(`terraform-plan.yaml`)는 PR에 plan 결과만 코멘트하고 apply는 하지 않는다.

---

## `k8s/` 구성 (ArgoCD 감시 대상)

```
bootstrap/root-app.yaml   → App of Apps 루트. ArgoCD 설치 직후 이것만 수동 apply, 이후 전부 자동
apps/*.yaml               → 컴포넌트별 ArgoCD Application 정의
values/*.yaml              → 헬름 차트 설정값 (terraform output 값 포함)
manifests/
  base/          → Namespace (monitoring / app / ai)
  karpenter/     → EC2NodeClass, NodePool 2종(AI용 On-Demand, Worker용 Spot)
  backend/       → FastAPI Deployment/Service/Ingress/PDB/KEDA ScaledObject
  ai/            → 동기화 · 학습 · 추론 · 권고 · 비용리포트 CronJob
```

### 배포 원리
1. `worldcup-backend` / `worldcup-ai`에서 push → CI가 이미지 빌드 → ECR에 태그로 저장 (이 단계는 배포가 아니다)
2. `k8s/manifests/{backend,ai}/*.yaml`의 이미지 태그를 새 값으로 수정해 커밋 — **이 커밋이 실제 배포 명령**
3. ArgoCD가 `k8s/` 변경을 감지해 클러스터에 반영

### Karpenter 이중 안전장치
- **taint/toleration**: AI NodePool에 taint를 걸어 일반 서비스 Pod가 실수로 비싼 AI 전용 노드에 스케줄되는 것을 차단
- **Spot 중단 대응**: SQS 인터럽션 큐로 2분 사전 통보를 Karpenter가 수신해 대체 노드를 먼저 띄우고 드레인. PDB + 인스턴스 타입 다양화(4~6종)로 회수 시에도 서비스 연속성 확보

---

## 사전 준비 (Bootstrap)

자세한 순서는 `docs/BOOTSTRAP.md` 참고. 요약:

1. State 백엔드용 S3 버킷 + DynamoDB 테이블 수동 생성
2. `terraform/environments/prod`에서 `terraform init && terraform apply` (network → eks → karpenter → database → security → ecr 순서 의존)
3. `terraform output` 값을 `k8s/values/*.yaml`에 복사
4. ArgoCD 헬름 설치 (수동, 1회) — 부트스트랩 자체는 GitOps로 못 함
5. `kubectl apply -f k8s/bootstrap/root-app.yaml` → 이후 전 컴포넌트 자동 배포
